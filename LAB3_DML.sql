CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INT,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INT,
    manager_id INT
);
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INT,
    start_date DATE,
    end_date DATE,
    budget INT
);

INSERT INTO employees (first_name, last_name, department)
VALUES ('Zhilkibaev', 'Bexultan', 'IT');

INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Zhenilmes', 'Aslanbek', 'HR', DEFAULT, DEFAULT);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES 
    ('IT', 200000, 1),
    ('HR', 150000, 2),
    ('Finance', 300000, 3);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zholdybaev', 'Asylzhan', 'Finance', 50000 * 1.1, CURRENT_DATE);

CREATE TEMP TABLE temp_employees AS
SELECT * 
FROM employees 
WHERE department = 'IT';

UPDATE employees
SET salary = salary * 1.10;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_name
);

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

DELETE FROM departments
WHERE dept_id::text NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, salary, department, hire_date, status)
VALUES (201, 'Alice Green', NULL, NULL, '2025-09-30', 'Active');

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

INSERT INTO employees (first_name, last_name, salary, department, hire_date, status)
VALUES ('Bob', 'White', 55000, 'Finance', '2025-09-30', 'Active')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
SELECT 'Emma','Johnson','IT',60000,CURRENT_DATE, 'Active'
WHERE NOT EXISTS (
	SELECT 1
	FROM employees
	WHERE first_name='Emma'
	AND last_name = 'Johnson'
);

UPDATE employees
SET salary = salary * 1.10
WHERE department IN (
    SELECT dept_name FROM departments WHERE budget > 100000
);

UPDATE employees
SET salary = salary * 1.05
WHERE department IN (
    SELECT dept_name FROM departments WHERE budget <= 100000
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES 
  ('Zhenisbek', 'Rakhat', 'Sales', 40000, CURRENT_DATE, 'Active'),
  ('Kuttybek', 'Meirzhan', 'HR', 42000, CURRENT_DATE, 'Active'),
  ('Makhan', 'Nurgisa', 'Finance', 50000, CURRENT_DATE, 'Active'),
  ('Razbek', 'Erkebulan', 'IT', 55000, CURRENT_DATE, 'Active'),
  ('Zhuztan', 'Mukhammed', 'Sales', 45000, CURRENT_DATE, 'Active');

UPDATE employees
SET salary = salary * 1.10
WHERE hire_date = CURRENT_DATE;

CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE 1=0; 

INSERT INTO employee_archive
SELECT * FROM employees WHERE status='Inactive';

DELETE FROM employees WHERE status='Inactive';

UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND dept_id IN (
      SELECT dept_id
      FROM departments d
      JOIN employees e ON e.department = d.dept_name
      GROUP BY d.dept_id
      HAVING COUNT(*) > 3
);

SELECT * FROM employees;
SELECT * FROM departments;
SELECT * FROM projects;


