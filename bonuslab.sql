BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    status TEXT CHECK (status IN ('active','blocked','frozen')) NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    daily_limit_kzt NUMERIC(18,2) NOT NULL
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    account_number TEXT UNIQUE NOT NULL,
    currency TEXT CHECK (currency IN ('KZT','USD','EUR','RUB')) NOT NULL,
    balance NUMERIC(18,2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    opened_at TIMESTAMP DEFAULT now(),
    closed_at TIMESTAMP
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency TEXT,
    to_currency TEXT,
    rate NUMERIC(18,6),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(18,2),
    currency TEXT,
    exchange_rate NUMERIC(18,6),
    amount_kzt NUMERIC(18,2),
    type TEXT,
    status TEXT,
    created_at TIMESTAMP DEFAULT now(),
    completed_at TIMESTAMP,
    description TEXT
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT,
    record_id INT,
    action TEXT,
    old_values JSONB,
    new_values JSONB,
    changed_by TEXT,
    changed_at TIMESTAMP DEFAULT now(),
    ip_address TEXT
);

CREATE OR REPLACE FUNCTION process_transfer(
    p_from_acc TEXT,
    p_to_acc TEXT,
    p_amount NUMERIC,
    p_currency TEXT,
    p_desc TEXT
) RETURNS VOID AS $$
DECLARE
    v_from_id INT;
    v_to_id INT;
    v_rate NUMERIC := 1;
    v_amount_kzt NUMERIC;
    v_limit NUMERIC;
    v_used NUMERIC;
BEGIN
    SELECT a.account_id, c.daily_limit_kzt INTO v_from_id, v_limit
    FROM accounts a JOIN customers c ON a.customer_id=c.customer_id
    WHERE a.account_number=p_from_acc AND a.is_active AND c.status='active'
    FOR UPDATE;

    IF v_from_id IS NULL THEN
        RAISE EXCEPTION 'SOURCE_ACCOUNT_INVALID' USING ERRCODE='P1001';
    END IF;

    SELECT account_id INTO v_to_id FROM accounts
    WHERE account_number=p_to_acc AND is_active FOR UPDATE;

    IF v_to_id IS NULL THEN
        RAISE EXCEPTION 'DEST_ACCOUNT_INVALID' USING ERRCODE='P1002';
    END IF;

    IF p_currency <> 'KZT' THEN
        SELECT rate INTO v_rate FROM exchange_rates
        WHERE from_currency=p_currency AND to_currency='KZT'
        ORDER BY valid_from DESC LIMIT 1;
    END IF;

    v_amount_kzt := p_amount * v_rate;

    SELECT COALESCE(SUM(amount_kzt),0) INTO v_used
    FROM transactions t
    JOIN accounts a ON t.from_account_id=a.account_id
    WHERE a.account_id=v_from_id AND DATE(created_at)=CURRENT_DATE;

    IF v_used + v_amount_kzt > v_limit THEN
        RAISE EXCEPTION 'DAILY_LIMIT_EXCEEDED' USING ERRCODE='P1003';
    END IF;

    UPDATE accounts SET balance = balance - p_amount WHERE account_id=v_from_id;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id=v_to_id;

    INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,completed_at,description)
    VALUES(v_from_id,v_to_id,p_amount,p_currency,v_rate,v_amount_kzt,'transfer','completed',now(),p_desc);

    INSERT INTO audit_log(table_name,record_id,action,new_values,changed_by)
    VALUES('transactions',currval('transactions_transaction_id_seq'),'INSERT',jsonb_build_object('amount',p_amount),'system');
END;
$$ LANGUAGE plpgsql;

CREATE VIEW customer_balance_summary AS
SELECT c.customer_id,c.full_name,a.account_number,a.balance,a.currency,
       SUM(a.balance*COALESCE(er.rate,1)) OVER (PARTITION BY c.customer_id) AS total_kzt,
       RANK() OVER (ORDER BY SUM(a.balance*COALESCE(er.rate,1)) OVER (PARTITION BY c.customer_id) DESC) AS rank
FROM customers c
JOIN accounts a ON c.customer_id=a.customer_id
LEFT JOIN exchange_rates er ON a.currency=er.from_currency AND er.to_currency='KZT';

CREATE VIEW daily_transaction_report AS
SELECT DATE(created_at) d,type,
       COUNT(*) cnt,
       SUM(amount_kzt) total,
       AVG(amount_kzt) avg_amt,
       SUM(SUM(amount_kzt)) OVER (ORDER BY DATE(created_at)) running_total,
       (SUM(amount_kzt)-LAG(SUM(amount_kzt)) OVER (ORDER BY DATE(created_at)))/NULLIF(LAG(SUM(amount_kzt)) OVER (ORDER BY DATE(created_at)),0)*100 AS growth
FROM transactions
GROUP BY d,type;

CREATE VIEW suspicious_activity_view WITH (security_barrier=true) AS
SELECT * FROM transactions
WHERE amount_kzt>5000000;

CREATE INDEX idx_accounts_active ON accounts(account_id) WHERE is_active;
CREATE INDEX idx_email_lower ON customers (LOWER(email));
CREATE INDEX idx_audit_jsonb ON audit_log USING GIN (new_values);
CREATE INDEX idx_tx_date_type ON transactions(created_at,type);
CREATE INDEX idx_tx_from_to ON transactions(from_account_id,to_account_id);

CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_acc TEXT,
    p_payments JSONB
) RETURNS JSONB AS $$
DECLARE
    v_company_id INT;
    v_total NUMERIC := 0;
    v_fail JSONB := '[]';
    rec JSONB;
BEGIN
    SELECT account_id INTO v_company_id FROM accounts
    WHERE account_number=p_company_acc FOR UPDATE;

    PERFORM pg_advisory_lock(v_company_id);

    FOR rec IN SELECT * FROM jsonb_array_elements(p_payments) LOOP
        v_total := v_total + (rec->>'amount')::NUMERIC;
    END LOOP;

    IF (SELECT balance FROM accounts WHERE account_id=v_company_id) < v_total THEN
        RAISE EXCEPTION 'INSUFFICIENT_FUNDS';
    END IF;

    FOR rec IN SELECT * FROM jsonb_array_elements(p_payments) LOOP
        BEGIN
            PERFORM process_transfer(p_company_acc,
                (SELECT account_number FROM accounts a JOIN customers c ON a.customer_id=c.customer_id WHERE c.iin=rec->>'iin' LIMIT 1),
                (rec->>'amount')::NUMERIC,'KZT',rec->>'description');
        EXCEPTION WHEN OTHERS THEN
            v_fail := v_fail || rec;
        END;
    END LOOP;

    PERFORM pg_advisory_unlock(v_company_id);

    RETURN jsonb_build_object('failed',v_fail);
END;
$$ LANGUAGE plpgsql;

COMMIT;
