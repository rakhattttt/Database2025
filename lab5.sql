CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

INSERT INTO employees VALUES (1, 'Nurgissa', 'Makhan', 25, 50000);
INSERT INTO employees VALUES (2, 'Erkebulan', 'Razbek', 30, 60000);

CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 
        AND discount_price > 0 
        AND discount_price < regular_price
    )
);

INSERT INTO products_catalog VALUES (1, 'Laptop', 1000, 800);
INSERT INTO products_catalog VALUES (2, 'Mouse', 50, 40);

CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

INSERT INTO bookings VALUES (1, '2024-01-10', '2024-01-15', 2);
INSERT INTO bookings VALUES (2, '2024-02-01', '2024-02-05', 4);

CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

INSERT INTO customers VALUES (1, 'nurgissa@email.com', '123-456-7890', '2024-01-01');
INSERT INTO customers VALUES (2, 'erkebulan@email.com', NULL, '2024-01-02');

CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO inventory VALUES (1, 'Widget A', 100, 19.99, '2024-01-01 10:00:00');
INSERT INTO inventory VALUES (2, 'Widget B', 50, 29.99, '2024-01-01 11:00:00');

CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

INSERT INTO users VALUES (1, 'nurgissa_makhan', 'nurgissa@email.com', '2024-01-01 09:00:00');
INSERT INTO users VALUES (2, 'erkebulan_razbek', 'erkebulan@email.com', '2024-01-01 10:00:00');

CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES (1, 101, 'CS101', 'Fall2024');
INSERT INTO course_enrollments VALUES (2, 102, 'CS101', 'Fall2024');

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

INSERT INTO users VALUES (1, 'rakhat_zhenisbek', 'rakhat@email.com', '2024-01-01 09:00:00');

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES (1, 'HR', 'New York');
INSERT INTO departments VALUES (2, 'IT', 'San Francisco');
INSERT INTO departments VALUES (3, 'Finance', 'Chicago');

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES (101, 201, '2024-01-15', 'A');
INSERT INTO student_courses VALUES (101, 202, '2024-01-15', 'B');
INSERT INTO student_courses VALUES (102, 201, '2024-01-16', 'A-');

CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Ulzhan Les', 1, '2023-01-15');
INSERT INTO employees_dept VALUES (2, 'Madiyar Duisenbay', 2, '2023-02-20');

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'J.K. Rowling', 'UK');
INSERT INTO authors VALUES (2, 'George R.R. Martin', 'USA');
INSERT INTO authors VALUES (3, 'J.R.R. Tolkien', 'UK');

INSERT INTO publishers VALUES (1, 'Penguin Random House', 'New York');
INSERT INTO publishers VALUES (2, 'HarperCollins', 'London');
INSERT INTO publishers VALUES (3, 'Simon & Schuster', 'New York');

INSERT INTO books VALUES (1, 'Harry Potter and the Philosopher''s Stone', 1, 1, 1997, '978-0439708180');
INSERT INTO books VALUES (2, 'A Game of Thrones', 2, 2, 1996, '978-0553103540');
INSERT INTO books VALUES (3, 'The Hobbit', 3, 1, 1937, '978-0547928227');

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk,
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO categories VALUES (2, 'Books');

INSERT INTO products_fk VALUES (1, 'Laptop', 1);
INSERT INTO products_fk VALUES (2, 'Novel', 2);

INSERT INTO orders VALUES (1, '2024-01-15');
INSERT INTO orders VALUES (2, '2024-01-16');

INSERT INTO order_items VALUES (1, 1, 1, 2);
INSERT INTO order_items VALUES (2, 1, 2, 1);
INSERT INTO order_items VALUES (3, 2, 1, 1);

CREATE TABLE ecommerce_customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE ecommerce_products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE ecommerce_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES ecommerce_customers ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE ecommerce_order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES ecommerce_orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES ecommerce_products ON DELETE RESTRICT,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);

INSERT INTO ecommerce_customers VALUES 
(1, 'Rakhat Zhenisbek', 'rakhat@email.com', '555-0101', '2024-01-01'),
(2, 'Bob Smith', 'bob@email.com', '555-0102', '2024-01-02'),
(3, 'Carol Davis', 'carol@email.com', '555-0103', '2024-01-03'),
(4, 'David Wilson', 'david@email.com', '555-0104', '2024-01-04'),
(5, 'Eva Brown', 'eva@email.com', '555-0105', '2024-01-05');

INSERT INTO ecommerce_products VALUES 
(1, 'Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 100),
(2, 'Mechanical Keyboard', 'RGB mechanical keyboard', 89.99, 50),
(3, 'Monitor 24"', '24 inch LED monitor', 199.99, 25),
(4, 'Laptop Stand', 'Adjustable laptop stand', 49.99, 75),
(5, 'USB-C Hub', '7-in-1 USB-C hub', 39.99, 150);

INSERT INTO ecommerce_orders VALUES 
(1, 1, '2024-01-10', 129.98, 'delivered'),
(2, 2, '2024-01-11', 289.98, 'processing'),
(3, 3, '2024-01-12', 49.99, 'shipped'),
(4, 4, '2024-01-13', 139.98, 'pending'),
(5, 5, '2024-01-14', 229.98, 'processing');

INSERT INTO ecommerce_order_details VALUES 
(1, 1, 1, 2, 29.99),
(2, 1, 4, 1, 49.99),
(3, 2, 2, 1, 89.99),
(4, 2, 3, 1, 199.99),
(5, 3, 4, 1, 49.99),
(6, 4, 1, 1, 29.99),
(7, 4, 5, 2, 39.99),
(8, 5, 2, 1, 89.99),
(9, 5, 3, 1, 199.99);

SELECT 'Employees' as table_name, COUNT(*) as record_count FROM employees
UNION ALL SELECT 'Products Catalog', COUNT(*) FROM products_catalog
UNION ALL SELECT 'Bookings', COUNT(*) FROM bookings
UNION ALL SELECT 'Customers', COUNT(*) FROM customers
UNION ALL SELECT 'Inventory', COUNT(*) FROM inventory
UNION ALL SELECT 'Users', COUNT(*) FROM users
UNION ALL SELECT 'Course Enrollments', COUNT(*) FROM course_enrollments
UNION ALL SELECT 'Departments', COUNT(*) FROM departments
UNION ALL SELECT 'Student Courses', COUNT(*) FROM student_courses
UNION ALL SELECT 'Employees Dept', COUNT(*) FROM employees_dept
UNION ALL SELECT 'Authors', COUNT(*) FROM authors
UNION ALL SELECT 'Publishers', COUNT(*) FROM publishers
UNION ALL SELECT 'Books', COUNT(*) FROM books
UNION ALL SELECT 'Categories', COUNT(*) FROM categories
UNION ALL SELECT 'Products FK', COUNT(*) FROM products_fk
UNION ALL SELECT 'Orders', COUNT(*) FROM orders
UNION ALL SELECT 'Order Items', COUNT(*) FROM order_items
UNION ALL SELECT 'E-commerce Customers', COUNT(*) FROM ecommerce_customers
UNION ALL SELECT 'E-commerce Products', COUNT(*) FROM ecommerce_products
UNION ALL SELECT 'E-commerce Orders', COUNT(*) FROM ecommerce_orders
UNION ALL SELECT 'E-commerce Order Details', COUNT(*) FROM ecommerce_order_details;
