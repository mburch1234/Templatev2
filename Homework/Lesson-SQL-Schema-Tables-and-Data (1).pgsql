-- ============================================================================
-- LESSON: PostgreSQL Schemas, Tables, and Data Management
-- ============================================================================
-- This lesson covers the core SQL skills you need to organize and manage
-- data in PostgreSQL. We'll go step by step through:
--
--   1-2.   Creating a SCHEMA and a TABLE
--   3-7.   Modifying columns (add, rename, change type, delete)
--   8-9.   Why multiple tables? What is a FOREIGN KEY?
--   10.    Creating a second table linked by a foreign key
--   11-12. Testing foreign keys (inserting data, breaking rules)
--   13.    Querying across tables with JOIN
--   14-15. Listing and dropping tables
--   16-20. Loading CSV data, manual inserts, updates, deletes
--
-- IMPORTANT: Run each section one at a time by highlighting the SQL
-- and pressing Ctrl+E (or F5) in PostgreSQL Explorer.
-- Do NOT run the entire file at once — some commands build on previous ones.
-- ============================================================================


-- ============================================================================
-- SECTION 1: WHAT IS A SCHEMA?
-- ============================================================================
-- Think of a DATABASE as a filing cabinet, and a SCHEMA as a drawer
-- inside that cabinet. Tables go inside schemas, just like folders
-- go inside a drawer.
--
-- PostgreSQL databases come with a default schema called "public".
-- But creating your OWN schema keeps your work organized and separate
-- from other people's tables.
--
-- Syntax:
--   CREATE SCHEMA schema_name;
--
-- Rules:
--   - Schema names must start with a letter or underscore
--   - They can contain letters, numbers, and underscores
--   - They are case-insensitive (my_schema = MY_SCHEMA)
-- ============================================================================

CREATE SCHEMA my_schema;

-- If you get an error "schema already exists", that's OK — it means
-- you already created it before. You can skip this step.


-- ============================================================================
-- SECTION 2: CREATING A TABLE
-- ============================================================================
-- A TABLE is where your actual data lives. It's like a spreadsheet:
--   - Each ROW is one record (one customer, one order, etc.)
--   - Each COLUMN is one piece of info (name, email, phone, etc.)
--
-- When you create a table, you define:
--   1. The table name
--   2. Each column's name
--   3. Each column's DATA TYPE (what kind of data it holds)
--   4. Any CONSTRAINTS (rules the data must follow)
--
-- ---- COMMON DATA TYPES ----
-- 
--   SERIAL        = Auto-incrementing integer (1, 2, 3, 4...)
--                   Perfect for ID columns — PostgreSQL fills this in
--                   automatically, so you never have to type an ID yourself.
--
--   INTEGER       = Whole numbers (no decimals): 1, 42, -7, 1000
--                   Use for counts, quantities, ages, etc.
--
--   VARCHAR(n)    = Text up to 'n' characters long.
--                   VARCHAR(100) means up to 100 characters.
--                   Use for names, emails, cities, etc.
--
--   TEXT          = Unlimited-length text.
--                   Use for long descriptions, comments, notes.
--
--   DATE          = A calendar date: '2025-03-22'
--                   Use for birthdays, order dates, etc.
--
--   TIMESTAMP     = Date AND time: '2025-03-22 14:30:00'
--                   Use for tracking when something happened.
--
--   NUMERIC(p, s) = Exact decimal number.
--                   p = total digits, s = digits after the decimal.
--                   NUMERIC(12, 2) can hold up to 9999999999.99
--                   Use for money, prices, financial data.
--
--   BOOLEAN       = TRUE or FALSE.
--                   Use for yes/no flags (is_active, is_paid, etc.)
--
-- ---- COMMON CONSTRAINTS ----
--
--   PRIMARY KEY   = Uniquely identifies each row. No duplicates allowed.
--                   Every table should have one. Usually the ID column.
--   
--   NOT NULL      = This column cannot be left blank.
--                   Use for required fields like names or emails.
--
--   UNIQUE        = No two rows can have the same value in this column.
--                   Use for emails, usernames, etc.
--
--   DEFAULT value = If no value is given, use this default.
--                   Example: DEFAULT CURRENT_TIMESTAMP fills in "right now".
--
-- ---- THE SYNTAX ----
--
--   CREATE TABLE schema_name.table_name (
--       column_name   DATA_TYPE   CONSTRAINTS,
--       column_name   DATA_TYPE   CONSTRAINTS,
--       ...
--   );
--
-- Let's create a customers table:
-- ============================================================================

CREATE TABLE my_schema.customers (

    -- customer_id: Auto-generated unique ID for each customer
    -- SERIAL = auto-incrementing (1, 2, 3...)
    -- PRIMARY KEY = must be unique, identifies each row
    customer_id   SERIAL PRIMARY KEY,

    -- first_name: Customer's first name, up to 100 characters
    first_name    VARCHAR(100),

    -- last_name: Customer's last name, up to 100 characters
    last_name     VARCHAR(100),

    -- email: Customer's email address, up to 255 characters
    email         VARCHAR(255),

    -- phone: Phone number stored as text (not a number!)
    -- We use VARCHAR because phone numbers can have dashes, 
    -- parentheses, and leading zeros: "(210) 555-0123"
    phone         VARCHAR(50),

    -- created_at: Timestamp of when this record was added
    -- DEFAULT CURRENT_TIMESTAMP means if you don't provide a value,
    -- PostgreSQL automatically fills in the current date and time
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- SECTION 3: VERIFYING YOUR TABLE WAS CREATED
-- ============================================================================
-- After creating a table, it's good practice to verify it exists.
-- We do this by querying the "information_schema" — a special built-in
-- set of tables that PostgreSQL maintains about YOUR tables.
--
-- information_schema.tables contains one row for every table in the
-- database. We filter it with WHERE to find only tables in our schema.
--
-- SELECT ... FROM ... WHERE ... is the most fundamental SQL query:
--   SELECT = which columns to show
--   FROM   = which table to look in
--   WHERE  = filter condition (only show rows that match)
-- ============================================================================

SELECT table_schema, table_name 
FROM information_schema.tables 
WHERE table_schema = 'my_schema';

-- You should see one row: my_schema | customers


-- ============================================================================
-- SECTION 4: MODIFYING A TABLE — ADDING COLUMNS
-- ============================================================================
-- After creating a table, you'll often need to add new columns.
-- Maybe you forgot a column, or your requirements changed.
--
-- The ALTER TABLE command lets you change an existing table's structure
-- WITHOUT deleting it or losing any data already in it.
--
-- Syntax for adding ONE column:
--   ALTER TABLE schema.table ADD COLUMN column_name DATA_TYPE;
--
-- Syntax for adding MULTIPLE columns at once:
--   ALTER TABLE schema.table
--       ADD COLUMN column1 DATA_TYPE,
--       ADD COLUMN column2 DATA_TYPE;
-- ============================================================================

-- Add a single column: city
ALTER TABLE my_schema.customers ADD COLUMN city VARCHAR(100);

-- Add two columns at once: state and zip_code
ALTER TABLE my_schema.customers 
    ADD COLUMN state VARCHAR(50),
    ADD COLUMN zip_code VARCHAR(20);

-- The table now has: customer_id, first_name, last_name, email, 
-- phone, created_at, city, state, zip_code


-- ============================================================================
-- SECTION 5: MODIFYING A TABLE — RENAMING A COLUMN
-- ============================================================================
-- If a column name is wrong or unclear, you can rename it.
-- This changes ONLY the name — the data inside stays the same.
--
-- Syntax:
--   ALTER TABLE schema.table RENAME COLUMN old_name TO new_name;
-- ============================================================================

-- Rename "city" to "city_name" for clarity
ALTER TABLE my_schema.customers RENAME COLUMN city TO city_name;

-- The column is now called city_name instead of city


-- ============================================================================
-- SECTION 6: MODIFYING A TABLE — CHANGING A COLUMN'S DATA TYPE
-- ============================================================================
-- Sometimes you need to change what kind of data a column holds.
-- For example, maybe you made zip_code VARCHAR(20) but really
-- only need VARCHAR(10) since US zip codes are 5 or 10 characters.
--
-- Syntax:
--   ALTER TABLE schema.table ALTER COLUMN column_name TYPE new_data_type;
--
-- WARNING: If the column already has data, the existing values must
-- be compatible with the new type. You can't change a text column
-- full of words to an INTEGER — that would fail.
-- ============================================================================

-- Shrink zip_code from VARCHAR(20) to VARCHAR(10)
ALTER TABLE my_schema.customers ALTER COLUMN zip_code TYPE VARCHAR(10);


-- ============================================================================
-- SECTION 7: MODIFYING A TABLE — DELETING (DROPPING) A COLUMN
-- ============================================================================
-- If you no longer need a column, you can remove it with DROP COLUMN.
--
-- ⚠️ WARNING: This permanently deletes the column AND all data in it.
-- There is no undo. Always double-check before dropping a column.
--
-- Syntax:
--   ALTER TABLE schema.table DROP COLUMN column_name;
-- ============================================================================

-- Remove the zip_code column entirely
ALTER TABLE my_schema.customers DROP COLUMN zip_code;

-- The zip_code column and any data in it are now gone forever


-- ============================================================================
-- SECTION 8: WHY DO WE NEED MORE THAN ONE TABLE?
-- ============================================================================
-- Imagine you run an online store. You could put EVERYTHING in one giant
-- table: customer name, address, order date, product, price...
--
-- But that creates problems:
--   - If a customer places 10 orders, their name and address are
--     repeated 10 times. That wastes space and invites typos.
--   - If a customer changes their email, you'd have to update it in
--     EVERY row for every order they placed.
--   - If you delete all of a customer's orders, you lose the customer
--     info too.
--
-- The solution: split data into SEPARATE TABLES and LINK them together.
--   - "customers" table: one row per customer (name, email, phone)
--   - "orders" table: one row per order (date, amount, status)
--   - The orders table has a customer_id column that says
--     "this order belongs to customer #5"
--
-- This is called NORMALIZATION — organizing data to reduce repetition.
-- ============================================================================


-- ============================================================================
-- SECTION 9: WHAT IS A FOREIGN KEY?
-- ============================================================================
-- A FOREIGN KEY is a column in one table that POINTS TO the PRIMARY KEY
-- of another table. It's like a link or reference between two tables.
--
-- Here's a visual of how our two tables will be connected:
--
--   CUSTOMERS TABLE                    ORDERS TABLE
--   ┌─────────────┬──────────┐        ┌──────────┬─────────────┬────────┐
--   │ customer_id │ name     │        │ order_id │ customer_id │ amount │
--   │ (PK)        │          │        │ (PK)     │ (FK) ───────┤        │
--   ├─────────────┼──────────┤        ├──────────┼─────────────┼────────┤
--   │ 1           │ Jane Doe │◄───────│ 101      │ 1           │ 59.99  │
--   │ 2           │ John S.  │◄──┐    │ 102      │ 1           │ 24.50  │
--   │ 3           │ Maria G. │   ├────│ 103      │ 2           │ 110.00 │
--   └─────────────┴──────────┘   │    │ 104      │ 2           │ 35.75  │
--                                │    └──────────┴─────────────┴────────┘
--                                │
--   PK = Primary Key (unique ID for each row in its own table)
--   FK = Foreign Key (points to a PK in another table)
--
-- KEY RULES enforced by a foreign key:
--
--   1. You CANNOT insert an order with customer_id = 999 if there is
--      no customer with customer_id = 999.
--      → PostgreSQL will give an error: "violates foreign key constraint"
--
--   2. You CANNOT delete a customer who still has orders.
--      → PostgreSQL won't let you accidentally orphan the orders.
--
--   3. The data types must match. If customers.customer_id is INTEGER,
--      then orders.customer_id must also be INTEGER.
--
-- This protection is called REFERENTIAL INTEGRITY — it guarantees that
-- every foreign key value actually points to a real, existing row.
-- ============================================================================


-- ============================================================================
-- SECTION 10: CREATING THE ORDERS TABLE WITH A FOREIGN KEY
-- ============================================================================
-- Now let's create the orders table. The key line is:
--
--   customer_id  INTEGER  REFERENCES my_schema.customers(customer_id)
--
-- Breaking that down:
--   customer_id       = the column name in our orders table
--   INTEGER           = data type (must match customers.customer_id's type)
--   REFERENCES        = "this column is a foreign key that points to..."
--   my_schema.customers(customer_id) = the table and column it points to
--
-- The full syntax for a foreign key:
--   column_name  DATA_TYPE  REFERENCES schema.other_table(other_column)
-- ============================================================================

CREATE TABLE my_schema.orders (

    -- order_id: Auto-generated unique ID for each order
    -- SERIAL = auto-incrementing (1, 2, 3...)
    -- PRIMARY KEY = must be unique, identifies each row in THIS table
    order_id      SERIAL PRIMARY KEY,

    -- customer_id: Links this order to a customer
    -- INTEGER = whole number (matches the type in the customers table)
    -- REFERENCES = this is a FOREIGN KEY — the value MUST exist in
    --              the customers table's customer_id column
    customer_id   INTEGER REFERENCES my_schema.customers(customer_id),

    -- order_date: When the order was placed (date only, no time)
    order_date    DATE,

    -- total_amount: Dollar amount with exactly 2 decimal places
    -- NUMERIC(12, 2) allows values up to 9,999,999,999.99
    total_amount  NUMERIC(12, 2),

    -- status: Current status of the order (text, up to 50 characters)
    -- Examples: 'pending', 'shipped', 'delivered', 'cancelled'
    status        VARCHAR(50)
);


-- ============================================================================
-- SECTION 11: TESTING THE FOREIGN KEY — INSERTING DATA
-- ============================================================================
-- Let's insert some data to see how the foreign key works in practice.
--
-- STEP 1: First, make sure we have customers (the "parent" table).
--         The foreign key requires the parent row to exist FIRST.
-- ============================================================================

-- Insert customers first (parent table)
INSERT INTO my_schema.customers (first_name, last_name, email, phone)
VALUES 
    ('Jane', 'Doe', 'jane.doe@email.com', '210-555-0101'),
    ('John', 'Smith', 'john.smith@email.com', '210-555-0102');

-- Check what customer_ids were assigned (we need these for orders)
SELECT customer_id, first_name, last_name FROM my_schema.customers;

-- Now insert orders that reference existing customers
-- The customer_id values below MUST match real customer_ids from above
INSERT INTO my_schema.orders (customer_id, order_date, total_amount, status)
VALUES
    (1, '2025-03-01', 59.99, 'delivered'),   -- Jane's order
    (1, '2025-03-15', 24.50, 'shipped'),     -- Another order by Jane
    (2, '2025-03-10', 110.00, 'pending');     -- John's order

-- Verify the orders were created
SELECT * FROM my_schema.orders;


-- ============================================================================
-- SECTION 12: TESTING THE FOREIGN KEY — WHAT HAPPENS WHEN YOU BREAK IT
-- ============================================================================
-- Try inserting an order for a customer that DOESN'T exist.
-- This will FAIL with an error — and that's a GOOD thing!
-- The foreign key is protecting your data from becoming inconsistent.
--
-- Uncomment the line below and run it to see the error:
-- ============================================================================

-- This will FAIL: there is no customer with customer_id = 999
-- INSERT INTO my_schema.orders (customer_id, order_date, total_amount, status)
-- VALUES (999, '2025-03-20', 50.00, 'pending');
--
-- Error you'd see: 
--   "insert or update on table "orders" violates foreign key constraint"
--   "Key (customer_id)=(999) is not present in table "customers""


-- ============================================================================
-- SECTION 13: QUERYING ACROSS RELATED TABLES WITH JOIN
-- ============================================================================
-- Now that we have two related tables, we can COMBINE their data using
-- a JOIN. A JOIN lets you pull columns from BOTH tables at once.
--
-- Think of it this way:
--   - The orders table has customer_id but NOT the customer's name
--   - The customers table has the name but NOT the order details
--   - A JOIN connects the matching rows so you get BOTH
--
-- Syntax:
--   SELECT columns
--   FROM table1
--   JOIN table2 ON table1.column = table2.column;
--
-- The ON clause tells PostgreSQL HOW to match the rows:
--   "Match orders to customers where the customer_id is the same"
-- ============================================================================

-- Combine customer names with their order details
SELECT 
    c.first_name,          -- from customers table
    c.last_name,           -- from customers table
    o.order_id,            -- from orders table
    o.order_date,          -- from orders table
    o.total_amount,        -- from orders table
    o.status               -- from orders table
FROM my_schema.customers c         -- "c" is a short alias for customers
JOIN my_schema.orders o            -- "o" is a short alias for orders
  ON c.customer_id = o.customer_id -- the matching condition
ORDER BY c.last_name, o.order_date;

-- The aliases "c" and "o" are shortcuts so you don't have to type
-- the full table name every time. They're optional but very helpful.
--
-- This query answers: "Show me each customer's name along with
-- their order details, sorted by last name then order date."


-- ============================================================================
-- SECTION 14: LISTING ALL TABLES IN YOUR SCHEMA
-- ============================================================================
-- Use this query anytime to see what tables exist in your schema.
-- ============================================================================

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'my_schema';

-- You should now see two tables: customers, orders


-- ============================================================================
-- SECTION 15: DELETING (DROPPING) A TABLE
-- ============================================================================
-- DROP TABLE permanently deletes a table AND all its data.
--
-- ⚠️ WARNING: This cannot be undone! All rows are deleted forever.
--
-- Syntax:
--   DROP TABLE schema.table;
--
-- If the table doesn't exist, you'll get an error. To avoid that:
--   DROP TABLE IF EXISTS schema.table;
-- ============================================================================

-- Remove the orders table (we'll recreate it later if needed)
DROP TABLE my_schema.orders;


-- ============================================================================
-- SECTION 16: LOADING DATA FROM A CSV FILE
-- ============================================================================
-- The COPY command loads data from a file on the server into a table.
-- This is the fastest way to bulk-load data into PostgreSQL.
--
-- Before running COPY, you need a CSV file. If you have an Excel (.xlsx)
-- file, first convert it to CSV using this terminal command:
--
--   python3 -c "
--   import pandas as pd
--   pd.read_excel('/path/to/your_file.xlsx').to_csv('/tmp/upload.csv', index=False)
--   "
--
-- How COPY works:
--   COPY schema.table (col1, col2, col3, ...)
--   FROM '/path/to/file.csv'
--   WITH (FORMAT csv, HEADER true);
--
-- Breaking that down:
--   COPY my_schema.customers  = which table to load into
--   (first_name, last_name, email, phone)  = which columns the CSV has
--                                     (must match the CSV column order!)
--   FROM '/tmp/upload.csv'    = path to the CSV file on the server
--   WITH (FORMAT csv,         = the file is CSV format
--         HEADER true)        = the first row is column names, skip it
--
-- IMPORTANT: The column names listed after COPY must match the order
-- of columns in your CSV file. You do NOT include auto-generated
-- columns like customer_id (PostgreSQL fills those in automatically).
-- ============================================================================

COPY my_schema.customers (first_name, last_name, email, phone)
FROM '/tmp/upload.csv'
WITH (FORMAT csv, HEADER true);


-- ============================================================================
-- SECTION 17: VERIFYING YOUR DATA
-- ============================================================================
-- After loading data, always verify it looks correct.
--
-- COUNT(*) = counts the total number of rows in the table
-- SELECT * = selects ALL columns
-- LIMIT 10 = only show the first 10 rows (so you don't flood your screen)
-- ============================================================================

-- How many rows were loaded?
SELECT COUNT(*) FROM my_schema.customers;

-- Look at the first 10 rows to make sure the data looks right
SELECT * FROM my_schema.customers LIMIT 10;


-- ============================================================================
-- SECTION 18: INSERTING DATA MANUALLY (ONE ROW AT A TIME)
-- ============================================================================
-- Besides loading from a file, you can add rows one at a time using INSERT.
-- This is useful for adding a few records or testing.
--
-- Syntax:
--   INSERT INTO schema.table (col1, col2, col3)
--   VALUES ('value1', 'value2', 'value3');
--
-- Notes:
--   - Text values go in single quotes: 'John'
--   - Numbers do NOT need quotes: 42
--   - You don't include SERIAL columns — they auto-fill
--   - You don't include DEFAULT columns unless you want a custom value
-- ============================================================================

-- Insert a single customer
INSERT INTO my_schema.customers (first_name, last_name, email, phone)
VALUES ('Jane', 'Doe', 'jane.doe@email.com', '210-555-0101');

-- Insert multiple customers at once (separate each row with a comma)
INSERT INTO my_schema.customers (first_name, last_name, email, phone)
VALUES 
    ('John', 'Smith', 'john.smith@email.com', '210-555-0102'),
    ('Maria', 'Garcia', 'maria.garcia@email.com', '210-555-0103'),
    ('James', 'Wilson', 'james.wilson@email.com', '210-555-0104');

-- Verify — you should see the new rows at the end
SELECT * FROM my_schema.customers ORDER BY customer_id DESC LIMIT 5;


-- ============================================================================
-- SECTION 19: UPDATING EXISTING DATA
-- ============================================================================
-- UPDATE changes values in rows that already exist.
--
-- Syntax:
--   UPDATE schema.table
--   SET column = 'new_value'
--   WHERE condition;
--
-- ⚠️ CRITICAL: Always include a WHERE clause!
-- Without WHERE, you'll update EVERY row in the table!
-- ============================================================================

-- Update Jane Doe's phone number
UPDATE my_schema.customers
SET phone = '210-555-9999'
WHERE first_name = 'Jane' AND last_name = 'Doe';

-- Update is safer with the unique ID:
-- UPDATE my_schema.customers SET phone = '210-555-9999' WHERE customer_id = 1;


-- ============================================================================
-- SECTION 20: DELETING ROWS
-- ============================================================================
-- DELETE removes rows from a table.
--
-- Syntax:
--   DELETE FROM schema.table WHERE condition;
--
-- ⚠️ CRITICAL: Always include a WHERE clause!
-- Without WHERE, you'll delete EVERY row in the table!
--
-- Difference between DELETE and DROP:
--   DELETE = removes rows (data) but the table still exists
--   DROP   = removes the entire table (structure + data)
-- ============================================================================

-- Delete one specific customer by ID
DELETE FROM my_schema.customers WHERE customer_id = 1;

-- Delete all customers named 'John Smith'
-- DELETE FROM my_schema.customers WHERE first_name = 'John' AND last_name = 'Smith';


-- ============================================================================
-- QUICK REFERENCE CHEAT SHEET
-- ============================================================================
--
-- CREATE SCHEMA my_schema;
-- DROP SCHEMA my_schema CASCADE;          -- deletes schema + all tables in it
--
-- CREATE TABLE my_schema.t (col TYPE, ...);
-- DROP TABLE my_schema.t;
-- DROP TABLE IF EXISTS my_schema.t;       -- no error if it doesn't exist
--
-- ALTER TABLE my_schema.t ADD COLUMN col TYPE;
-- ALTER TABLE my_schema.t DROP COLUMN col;
-- ALTER TABLE my_schema.t RENAME COLUMN old TO new;
-- ALTER TABLE my_schema.t ALTER COLUMN col TYPE new_type;
--
-- INSERT INTO my_schema.t (col1, col2) VALUES ('a', 'b');
-- UPDATE my_schema.t SET col = 'val' WHERE condition;
-- DELETE FROM my_schema.t WHERE condition;
--
-- FOREIGN KEYS:
-- col INTEGER REFERENCES my_schema.other_table(other_col)  -- in CREATE TABLE
--
-- JOINS (combining two tables):
-- SELECT a.col, b.col FROM my_schema.t1 a
-- JOIN my_schema.t2 b ON a.id = b.id;
--
-- COPY my_schema.t (col1, col2) FROM '/path.csv' WITH (FORMAT csv, HEADER true);
--
-- SELECT * FROM my_schema.t;              -- all columns, all rows
-- SELECT col1, col2 FROM my_schema.t;     -- specific columns
-- SELECT * FROM my_schema.t LIMIT 10;     -- first 10 rows
-- SELECT COUNT(*) FROM my_schema.t;       -- count rows
-- SELECT * FROM my_schema.t WHERE col = 'val';  -- filtered rows
-- SELECT * FROM my_schema.t ORDER BY col;        -- sorted rows
--
-- ============================================================================
