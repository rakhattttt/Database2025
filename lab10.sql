CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob', 500.00),
    ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00),
    ('Joe''s Shop', 'Fanta', 3.50);

BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
COMMIT;

BEGIN;
UPDATE accounts SET balance = balance - 500.00 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
DELETE FROM products WHERE shop = 'Joe''s Shop';
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
SELECT MAX(price), MIN(price) FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;

BEGIN;
UPDATE products SET price = 99.99 WHERE product = 'Fanta';
ROLLBACK;

CREATE OR REPLACE FUNCTION transfer_if_enough(from_name text, to_name text, amount numeric)
RETURNS TEXT AS $$
DECLARE
    from_balance numeric;
BEGIN
    SELECT balance INTO from_balance FROM accounts WHERE name = from_name FOR UPDATE;
    IF from_balance IS NULL THEN
        RETURN 'Source account not found';
    END IF;
    IF from_balance < amount THEN
        RETURN 'Insufficient funds';
    END IF;
    UPDATE accounts SET balance = balance - amount WHERE name = from_name;
    UPDATE accounts SET balance = balance + amount WHERE name = to_name;
    RETURN 'OK';
EXCEPTION
    WHEN others THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

SELECT transfer_if_enough('Bob', 'Wally', 200.00);

BEGIN;
INSERT INTO products (shop, product, price) VALUES ('Joe''s Shop', 'NewDrink', 5.00);
SAVEPOINT sp_a;
UPDATE products SET price = 6.50 WHERE shop = 'Joe''s Shop' AND product = 'NewDrink';
SAVEPOINT sp_b;
DELETE FROM products WHERE shop = 'Joe''s Shop' AND product = 'NewDrink';
ROLLBACK TO sp_a;
COMMIT;

BEGIN;
SELECT balance FROM accounts WHERE name='Shared' FOR UPDATE;
UPDATE accounts SET balance = balance - 80 WHERE name='Shared';
COMMIT;

BEGIN;
SELECT balance FROM accounts WHERE name='Shared' FOR UPDATE;
UPDATE accounts SET balance = balance - 80 WHERE name='Shared';
COMMIT;
