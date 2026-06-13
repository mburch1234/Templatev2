-- Active: 1774905351243@@localhost@5432@student@hotdog
-- ============================================================================
-- LESSON: Hotdog Stand — End-to-End SQL
-- ============================================================================
-- This lesson walks through the COMPLETE lifecycle of working with a
-- relational database using ONE consistent dataset: the Hotdog Stand.
--
-- We start from nothing and build up to real business analysis:
--
--   PART 1:  Creating a Schema (organizing your database)
--   PART 2:  Creating Tables (designing your data structure)
--   PART 3:  Loading Data from CSV Files
--   PART 4:  Exploring Your Data (SELECT, WHERE, ORDER BY)
--   PART 5:  Table Aliases — Giving Tables Nicknames
--   PART 6:  Joins — Combining Tables
--   PART 7:  Bridging Tables — Many-to-Many Relationships
--   PART 8:  Handling NULL / Missing Values
--   PART 9:  Text Cleaning & Data Standardization
--   PART 10: Math Functions & Business Calculations
--   PART 11: Putting It All Together — Business Reports
--
-- PREREQUISITES:
--   - PostgreSQL running with a database called "student"
--   - CSV files in /workspaces/MS3083_Template_V2/data/hotdog/
--
-- HOW TO USE THIS FILE:
--   Highlight ONE section at a time and press Ctrl+E (or F5) to run it.
--   Read the comments BEFORE you run each query so you know what to expect.
--   Do NOT run the entire file at once — some sections build on previous ones.
-- ============================================================================


-- ############################################################################
--
--     PART 1: CREATING A SCHEMA — ORGANIZING YOUR DATABASE
--
-- ############################################################################
--
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

-- Drop the schema if it already exists (CASCADE drops all its tables too)
DROP SCHEMA IF EXISTS hotdog CASCADE;

-- Create a fresh schema for our hotdog stand
CREATE SCHEMA hotdog;

-- You now have an empty drawer labeled "hotdog" in your database.
-- All our tables will go inside this schema.


-- ############################################################################
--
--     PART 2: CREATING TABLES — DESIGNING YOUR DATA STRUCTURE
--
-- ############################################################################
--
-- A TABLE is where your actual data lives. It's like a spreadsheet:
--   - Each ROW is one record (one owner, one sale, etc.)
--   - Each COLUMN is one piece of info (name, email, price, etc.)
--
-- When you create a table, you define:
--   1. The table name
--   2. Each column's name
--   3. Each column's DATA TYPE (what kind of data it holds)
--   4. Any CONSTRAINTS (rules the data must follow)
--
-- ---- QUICK DATA TYPE REFERENCE ----
--   SERIAL        = Auto-incrementing integer (1, 2, 3...) for IDs
--   INTEGER       = Whole numbers (no decimals)
--   VARCHAR(n)    = Text up to 'n' characters
--   TEXT          = Unlimited-length text
--   DATE          = Calendar date: '2026-03-22'
--   TIMESTAMP     = Date + time: '2026-03-22 14:30:00'
--   NUMERIC(p,s)  = Exact decimal: NUMERIC(8,2) = up to 999999.99
--   BOOLEAN       = TRUE or FALSE
--
-- ---- QUICK CONSTRAINT REFERENCE ----
--   PRIMARY KEY   = Uniquely identifies each row (no duplicates)
--   NOT NULL      = This column cannot be left blank
--   REFERENCES    = Foreign key — links to another table's primary key
--   DEFAULT       = Sets an automatic value if none is provided
-- ============================================================================


-- -------------------------------------------------------
-- TABLE 1: OWNERS — who owns/runs the hotdog stand
-- -------------------------------------------------------
CREATE TABLE hotdog.owners (
    owner_id    SERIAL PRIMARY KEY,
    first_name  VARCHAR(50)  NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------
-- TABLE 2: VENDORS — suppliers who provide ingredients
-- -------------------------------------------------------
CREATE TABLE hotdog.vendors (
    vendor_id    SERIAL PRIMARY KEY,
    vendor_name  VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    phone        VARCHAR(20),
    email        VARCHAR(100),
    address      VARCHAR(200),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------
-- TABLE 3: INGREDIENTS — buns, franks, condiments, etc.
-- -------------------------------------------------------
CREATE TABLE hotdog.ingredients (
    ingredient_id   SERIAL PRIMARY KEY,
    ingredient_name VARCHAR(100) NOT NULL,
    unit            VARCHAR(20)  NOT NULL,  -- 'each', 'oz', 'lb', 'bottle'
    cost_per_unit   NUMERIC(8,2) NOT NULL,
    vendor_id       INT REFERENCES hotdog.vendors(vendor_id)
);
-- Notice: vendor_id REFERENCES hotdog.vendors — this is a FOREIGN KEY.
-- It means every ingredient MUST link to a valid vendor.

-- -------------------------------------------------------
-- TABLE 4: INVENTORY — current stock levels
-- -------------------------------------------------------
CREATE TABLE hotdog.inventory (
    inventory_id    SERIAL PRIMARY KEY,
    ingredient_id   INT NOT NULL REFERENCES hotdog.ingredients(ingredient_id),
    quantity        NUMERIC(10,2) NOT NULL DEFAULT 0,
    reorder_level   NUMERIC(10,2) NOT NULL DEFAULT 10,
    last_restocked  DATE,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------
-- TABLE 5: MENU_ITEMS — what customers can buy
-- -------------------------------------------------------
CREATE TABLE hotdog.menu_items (
    menu_item_id  SERIAL PRIMARY KEY,
    item_name     VARCHAR(100) NOT NULL,
    description   VARCHAR(255),
    price         NUMERIC(6,2) NOT NULL,
    is_available  BOOLEAN DEFAULT TRUE
);

-- -------------------------------------------------------
-- TABLE 6: MENU_ITEM_INGREDIENTS — the recipe (BRIDGING TABLE!)
-- This connects menu_items ↔ ingredients (many-to-many)
-- -------------------------------------------------------
CREATE TABLE hotdog.menu_item_ingredients (
    menu_item_ingredient_id SERIAL PRIMARY KEY,
    menu_item_id   INT NOT NULL REFERENCES hotdog.menu_items(menu_item_id),
    ingredient_id  INT NOT NULL REFERENCES hotdog.ingredients(ingredient_id),
    quantity_used  NUMERIC(8,2) NOT NULL  -- how much of the ingredient per serving
);

-- -------------------------------------------------------
-- TABLE 7: SALES — each transaction / order
-- -------------------------------------------------------
CREATE TABLE hotdog.sales (
    sale_id      SERIAL PRIMARY KEY,
    sale_date    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    owner_id     INT REFERENCES hotdog.owners(owner_id),
    total_amount NUMERIC(8,2),
    payment_type VARCHAR(20) DEFAULT 'cash'  -- 'cash', 'card', 'mobile'
);

-- -------------------------------------------------------
-- TABLE 8: SALE_ITEMS — line items in each sale
-- -------------------------------------------------------
CREATE TABLE hotdog.sale_items (
    sale_item_id  SERIAL PRIMARY KEY,
    sale_id       INT NOT NULL REFERENCES hotdog.sales(sale_id),
    menu_item_id  INT NOT NULL REFERENCES hotdog.menu_items(menu_item_id),
    quantity      INT NOT NULL DEFAULT 1,
    line_total    NUMERIC(8,2) NOT NULL
);


-- HOW THE TABLES CONNECT:
--
--   owners ──────────┐
--                     ├──► sales ──────► sale_items ──► menu_items
--   vendors ──► ingredients ──► inventory
--                     │
--                     └──► menu_item_ingredients (bridge)
--
-- The arrows show how tables connect through foreign key columns.


-- ############################################################################
--
--     PART 3: LOADING DATA FROM CSV FILES
--
-- ############################################################################
--
-- The COPY command loads data from CSV files directly into tables.
-- IMPORTANT: Load parent tables FIRST, then child tables.
-- (You can't load sale_items before sales exist — the foreign keys
-- would have nothing to point to!)
-- ============================================================================

-- Load owners
COPY hotdog.owners (owner_id, first_name, last_name, email, phone)
FROM '/workspaces/MS3083_Template_V2/data/hotdog/owners.csv'
WITH (FORMAT csv, HEADER true);

-- Load vendors
COPY hotdog.vendors (vendor_id, vendor_name, contact_name, phone, email, address)
FROM '/workspaces/MS3083_Template_V2/data/hotdog/vendors.csv'
WITH (FORMAT csv, HEADER true);

-- Load ingredients
COPY hotdog.ingredients (ingredient_id, ingredient_name, unit, cost_per_unit, vendor_id)
FROM '/workspaces/MS3083_Template_V2/data/hotdog/ingredients.csv'
WITH (FORMAT csv, HEADER true);

-- Load inventory
COPY hotdog.inventory (inventory_id, ingredient_id, quantity, reorder_level, last_restocked)
FROM '/workspaces/MS3083_Template_V2/data/hotdog/inventory.csv'
WITH (FORMAT csv, HEADER true);

-- Load menu items
COPY hotdog.menu_items (menu_item_id, item_name, description, price, is_available)
FROM '/workspaces/MS3083_Template_V2/data/hotdog/menu_items.csv'
WITH (FORMAT csv, HEADER true);

-- Load menu item ingredients (recipes — the bridge table)
COPY hotdog.menu_item_ingredients (menu_item_ingredient_id, menu_item_id, ingredient_id, quantity_used)
FROM '/workspaces/MS3083_Template_V2/data/hotdog/menu_item_ingredients.csv'
WITH (FORMAT csv, HEADER true);

-- Load sales
COPY hotdog.sales (sale_id, sale_date, owner_id, total_amount, payment_type)
FROM '/workspaces/MS3083_Template_V2/data/hotdog/sales.csv'
WITH (FORMAT csv, HEADER true);

-- Load sale items
COPY hotdog.sale_items (sale_item_id, sale_id, menu_item_id, quantity, line_total)
FROM '/workspaces/MS3083_Template_V2/data/hotdog/sale_items.csv'
WITH (FORMAT csv, HEADER true);

-- Reset sequences so future INSERTs get the right IDs
SELECT setval('hotdog.owners_owner_id_seq',      (SELECT MAX(owner_id) FROM hotdog.owners));
SELECT setval('hotdog.vendors_vendor_id_seq',     (SELECT MAX(vendor_id) FROM hotdog.vendors));
SELECT setval('hotdog.ingredients_ingredient_id_seq', (SELECT MAX(ingredient_id) FROM hotdog.ingredients));
SELECT setval('hotdog.inventory_inventory_id_seq', (SELECT MAX(inventory_id) FROM hotdog.inventory));
SELECT setval('hotdog.menu_items_menu_item_id_seq', (SELECT MAX(menu_item_id) FROM hotdog.menu_items));
SELECT setval('hotdog.menu_item_ingredients_menu_item_ingredient_id_seq', (SELECT MAX(menu_item_ingredient_id) FROM hotdog.menu_item_ingredients));
SELECT setval('hotdog.sales_sale_id_seq',         (SELECT MAX(sale_id) FROM hotdog.sales));
SELECT setval('hotdog.sale_items_sale_item_id_seq', (SELECT MAX(sale_item_id) FROM hotdog.sale_items));

-- VERIFY: Quick row counts for every table
SELECT 'owners'               AS table_name, COUNT(*) AS row_count FROM hotdog.owners
UNION ALL SELECT 'vendors',             COUNT(*) FROM hotdog.vendors
UNION ALL SELECT 'ingredients',         COUNT(*) FROM hotdog.ingredients
UNION ALL SELECT 'inventory',           COUNT(*) FROM hotdog.inventory
UNION ALL SELECT 'menu_items',          COUNT(*) FROM hotdog.menu_items
UNION ALL SELECT 'menu_item_ingredients', COUNT(*) FROM hotdog.menu_item_ingredients
UNION ALL SELECT 'sales',               COUNT(*) FROM hotdog.sales
UNION ALL SELECT 'sale_items',          COUNT(*) FROM hotdog.sale_items
ORDER BY table_name;


-- ############################################################################
--
--     PART 4: EXPLORING YOUR DATA — SELECT, WHERE, ORDER BY
--
-- ############################################################################
--
-- Now that the data is loaded, let's look around!
-- These are the fundamental tools you'll use every single time you
-- write SQL:
--
--   SELECT   = choose WHICH columns you want to see
--   FROM     = choose WHICH table to pull data from
--   WHERE    = filter rows that meet a condition
--   ORDER BY = sort the results
--   LIMIT    = only show the first N rows
-- ============================================================================


-- ============================================================================
-- SECTION 4.1: SEE EVERYTHING IN A TABLE
-- ============================================================================

-- The asterisk (*) means "all columns"
SELECT * FROM hotdog.owners;
SELECT * FROM hotdog.menu_items;
SELECT * FROM hotdog.sales LIMIT 10;   -- just the first 10 sales


-- ============================================================================
-- SECTION 4.2: SELECT SPECIFIC COLUMNS
-- ============================================================================
-- Don't always use SELECT * — pick just the columns you need.
-- This makes results easier to read.

SELECT item_name, price
FROM hotdog.menu_items
ORDER BY price;


-- ============================================================================
-- SECTION 4.3: FILTER WITH WHERE
-- ============================================================================

-- Menu items that cost more than $5.00
SELECT item_name, price
FROM hotdog.menu_items
WHERE price > 5.00
ORDER BY price;

-- Cash sales only
SELECT sale_id, sale_date, total_amount
FROM hotdog.sales
WHERE payment_type = 'cash'
ORDER BY total_amount DESC
LIMIT 5;

-- Ingredients supplied by vendor #1
SELECT ingredient_name, cost_per_unit
FROM hotdog.ingredients
WHERE vendor_id = 1;


-- ############################################################################
--
--     PART 5: TABLE ALIASES — GIVING TABLES NICKNAMES
--
-- ############################################################################
--
-- WHAT'S THE PROBLEM?
--   When you work with two or more tables, they might both have a
--   column with the SAME name. For example, both "owners" and "sales"
--   have a column called "created_at". If you write:
--       SELECT created_at FROM hotdog.owners, hotdog.sales ...
--   SQL won't know which table you mean — and it gives you an error.
--
-- THE FIX: Give each table a short NICKNAME (called an "alias").
--
-- SYNTAX:
--   FROM  hotdog.sales  AS  s       ← "s" is now a nickname for sales
--   JOIN  hotdog.owners AS  o       ← "o" is now a nickname for owners
--
-- Then use the nickname before each column:
--   s.sale_id,  s.total_amount       ← from the sales table
--   o.first_name, o.last_name        ← from the owners table
--
-- REAL-WORLD ANALOGY:
--   You have two friends both named "Tony":
--     Tony M. → the owner who works the morning shift
--     Tony R. → a regular customer
--   You add the initial so people know which Tony you're talking about.
--   Table aliases work the same way.
--
-- RULES:
--   - Pick a short abbreviation (first letter(s) of the table name)
--   - The AS keyword is optional: FROM hotdog.sales s  works too
--   - Once you alias a table, use that alias for ALL its columns
--
-- ---- STANDARD ALIASES FOR OUR HOTDOG STAND ----
--   hotdog.owners                  → o
--   hotdog.vendors                 → v
--   hotdog.ingredients             → i   (or ing)
--   hotdog.inventory               → inv
--   hotdog.menu_items              → mi
--   hotdog.menu_item_ingredients   → mii (or bridge)
--   hotdog.sales                   → s
--   hotdog.sale_items              → si
-- ============================================================================


-- ============================================================================
-- SECTION 5.1: ALIASES IN ACTION
-- ============================================================================

-- WITHOUT aliases — works when column names are unique:
SELECT sale_id, sale_date, total_amount
FROM hotdog.sales
LIMIT 5;

-- WITH aliases — REQUIRED when joining so SQL knows which table you mean:
SELECT
    s.sale_id,
    s.sale_date,
    s.total_amount,
    o.first_name,
    o.last_name
FROM hotdog.sales  AS s
JOIN hotdog.owners AS o  ON s.owner_id = o.owner_id
LIMIT 5;

-- The alias "s" stands for sales, "o" stands for owners.
-- s.sale_id means "the sale_id column FROM the sales table."
-- o.first_name means "the first_name column FROM the owners table."


-- ============================================================================
-- SECTION 5.2: COLUMN ALIASES — RENAMING OUTPUT COLUMNS
-- ============================================================================
-- You can also give COLUMNS nicknames to make output more readable.
-- Use AS after any expression:

SELECT
    o.first_name || ' ' || o.last_name  AS owner_name,   -- combine into one column
    s.total_amount                      AS sale_total,    -- rename for clarity
    s.payment_type                      AS paid_with
FROM hotdog.sales  AS s
JOIN hotdog.owners AS o  ON s.owner_id = o.owner_id
LIMIT 5;

-- "owner_name", "sale_total", and "paid_with" are the column headers
-- you'll see in the results — much nicer than seeing a formula!


-- ############################################################################
--
--     PART 6: JOINS — COMBINING TABLES
--
-- ############################################################################
--
-- Data lives in separate tables to avoid repetition.
-- JOINs let you pull data from TWO (or more) tables at once by
-- matching rows on a shared column (usually an ID).
--
-- JOIN TYPES AT A GLANCE:
--   INNER JOIN       → Only rows that match in BOTH tables
--   LEFT JOIN        → ALL rows from the left table + matches from right
--   RIGHT JOIN       → ALL rows from the right table + matches from left
--   FULL OUTER JOIN  → ALL rows from BOTH tables
--
-- SYNTAX:
--   SELECT columns
--   FROM table_a AS a
--   JOIN table_b AS b  ON a.key = b.key;
-- ============================================================================


-- ============================================================================
-- SECTION 6.1: INNER JOIN — SALES + OWNERS
-- ============================================================================
-- Question: "Who was working when each sale was made?"
-- We need: sales (the sale info) + owners (the person's name)

SELECT
    s.sale_id,
    s.sale_date,
    o.first_name || ' ' || o.last_name AS owner_name,
    s.total_amount,
    s.payment_type
FROM hotdog.sales  AS s
INNER JOIN hotdog.owners AS o  ON s.owner_id = o.owner_id
ORDER BY s.sale_id
LIMIT 10;

-- The ON clause is the key:  ON s.owner_id = o.owner_id
-- "Line up each sale with the owner who has the SAME owner_id."


-- ============================================================================
-- SECTION 6.2: INNER JOIN — SALE ITEMS + MENU ITEMS
-- ============================================================================
-- Question: "What items were sold and at what price?"

SELECT
    si.sale_id,
    mi.item_name,
    mi.price       AS menu_price,
    si.quantity,
    si.line_total
FROM hotdog.sale_items AS si
INNER JOIN hotdog.menu_items AS mi  ON si.menu_item_id = mi.menu_item_id
ORDER BY si.sale_id, si.sale_item_id
LIMIT 15;


-- ============================================================================
-- SECTION 6.3: INNER JOIN — INGREDIENTS + VENDORS
-- ============================================================================
-- Question: "Which vendor supplies each ingredient?"

SELECT
    i.ingredient_name,
    i.cost_per_unit,
    i.unit,
    v.vendor_name,
    v.contact_name
FROM hotdog.ingredients AS i
INNER JOIN hotdog.vendors AS v  ON i.vendor_id = v.vendor_id
ORDER BY v.vendor_name, i.ingredient_name;


-- ============================================================================
-- SECTION 6.4: LEFT JOIN — KEEP EVERYTHING ON THE LEFT
-- ============================================================================
-- LEFT JOIN keeps ALL rows from the LEFT table, even if there's no
-- matching row in the RIGHT table. Unmatched columns show NULL.
--
-- Let's add a menu item that has never been sold:

INSERT INTO hotdog.menu_items (item_name, description, price, is_available)
VALUES ('Fiesta Dog', 'Beef frank with pico de gallo, guacamole, and lime crema', 6.50, TRUE)
ON CONFLICT DO NOTHING;

-- INNER JOIN — Fiesta Dog DISAPPEARS (no sales to match with)
SELECT
    mi.item_name,
    COUNT(si.sale_item_id) AS times_sold
FROM hotdog.menu_items AS mi
INNER JOIN hotdog.sale_items AS si  ON mi.menu_item_id = si.menu_item_id
GROUP BY mi.item_name
ORDER BY times_sold DESC;

-- LEFT JOIN — Fiesta Dog STAYS with 0 sales
SELECT
    mi.item_name,
    COUNT(si.sale_item_id) AS times_sold
FROM hotdog.menu_items AS mi
LEFT JOIN hotdog.sale_items AS si  ON mi.menu_item_id = si.menu_item_id
GROUP BY mi.item_name
ORDER BY times_sold DESC;


-- ============================================================================
-- SECTION 6.5: LEFT JOIN — ALL OWNERS AND THEIR REVENUE
-- ============================================================================

SELECT
    o.first_name || ' ' || o.last_name AS owner_name,
    COUNT(s.sale_id)                   AS number_of_sales,
    COALESCE(SUM(s.total_amount), 0)   AS total_revenue
FROM hotdog.owners AS o
LEFT JOIN hotdog.sales AS s  ON o.owner_id = s.owner_id
GROUP BY o.owner_id, o.first_name, o.last_name
ORDER BY total_revenue DESC;


-- ============================================================================
-- SECTION 6.6: MULTI-TABLE JOIN — FULL SALES DETAIL (4 tables!)
-- ============================================================================
-- Question: "For each sale, show who sold it, what was ordered, and
-- the item name — all in one result."

SELECT
    s.sale_id,
    s.sale_date,
    o.first_name || ' ' || o.last_name AS owner_name,
    mi.item_name,
    si.quantity,
    si.line_total,
    s.payment_type
FROM hotdog.sales      AS s
JOIN hotdog.owners     AS o   ON s.owner_id     = o.owner_id
JOIN hotdog.sale_items AS si  ON s.sale_id       = si.sale_id
JOIN hotdog.menu_items AS mi  ON si.menu_item_id = mi.menu_item_id
ORDER BY s.sale_id, si.sale_item_id
LIMIT 20;

-- Four tables joined! Here's the chain:
--   s  = sales        → WHEN did the sale happen?
--   o  = owners       → WHO was working?
--   si = sale_items   → WHAT was on the receipt?
--   mi = menu_items   → What's the item NAME?
-- Each JOIN follows one link. Take it one line at a time!


-- ############################################################################
--
--     PART 7: BRIDGING TABLES — MANY-TO-MANY RELATIONSHIPS
--
-- ############################################################################
--
-- A bridging table (junction table) connects two tables that have a
-- MANY-TO-MANY relationship.
--
-- IN OUR HOTDOG STAND:
--   - One MENU ITEM uses MANY ingredients
--   - One INGREDIENT is in MANY menu items
--   - The bridging table: menu_item_ingredients
--
-- ┌──────────────┐     ┌───────────────────────┐     ┌──────────────┐
-- │  menu_items   │     │ menu_item_ingredients  │     │ ingredients  │
-- │──────────────│     │ (BRIDGING TABLE)       │     │──────────────│
-- │ menu_item_id ◄─────│ menu_item_id           │     │ingredient_id │
-- │ item_name    │     │ ingredient_id          ├────►│ingredient_name│
-- │ price        │     │ quantity_used          │     │ cost_per_unit│
-- └──────────────┘     └───────────────────────┘     └──────────────┘
-- ============================================================================


-- ============================================================================
-- SECTION 7.1: LOOK AT THE RAW BRIDGE TABLE
-- ============================================================================

SELECT *
FROM hotdog.menu_item_ingredients
ORDER BY menu_item_id, ingredient_id;
-- By itself it's just ID numbers — not very useful to read.


-- ============================================================================
-- SECTION 7.2: JOIN THROUGH THE BRIDGE TO SEE NAMES
-- ============================================================================
-- Start at the bridge, JOIN to BOTH parent tables to get readable names.

SELECT
    mi.item_name,
    i.ingredient_name,
    bridge.quantity_used,
    i.unit
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items  AS mi ON bridge.menu_item_id  = mi.menu_item_id
JOIN hotdog.ingredients AS i  ON bridge.ingredient_id = i.ingredient_id
ORDER BY mi.item_name, i.ingredient_name;

-- NOW you can read it: "Classic Dog uses Beef Frank, Ketchup, etc."


-- ============================================================================
-- SECTION 7.3: COMMON QUESTIONS ANSWERED WITH THE BRIDGE
-- ============================================================================

-- Q: "What ingredients are in the Chili Cheese Dog?"
SELECT
    i.ingredient_name,
    bridge.quantity_used,
    i.unit
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items  AS mi ON bridge.menu_item_id  = mi.menu_item_id
JOIN hotdog.ingredients AS i  ON bridge.ingredient_id = i.ingredient_id
WHERE mi.item_name = 'Chili Cheese Dog';

-- Q: "Which menu items use Beef Frank?"
SELECT
    mi.item_name,
    mi.price
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items  AS mi ON bridge.menu_item_id  = mi.menu_item_id
JOIN hotdog.ingredients AS i  ON bridge.ingredient_id = i.ingredient_id
WHERE i.ingredient_name = 'Beef Frank'
ORDER BY mi.item_name;

-- Q: "How many ingredients does each menu item use?"
SELECT
    mi.item_name,
    COUNT(*) AS number_of_ingredients
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items AS mi ON bridge.menu_item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY number_of_ingredients DESC;


-- ############################################################################
--
--     PART 8: HANDLING NULL / MISSING VALUES
--
-- ############################################################################
--
-- NULL means "missing" or "unknown."  It is NOT zero. It is NOT blank.
-- It is the complete absence of a value.
--
-- RULES:
--   WRONG:   WHERE email = NULL       ← NEVER works!
--   RIGHT:   WHERE email IS NULL      ← correct way to check
--
--   Any math with NULL gives NULL:  5 + NULL = NULL  (not 5!)
--
-- KEY FUNCTIONS:
--   COALESCE(value, default) → replaces NULL with a default
--   NULLIF(a, b)             → returns NULL if a equals b
-- ============================================================================


-- ============================================================================
-- SECTION 8.1: SET UP MESSY REVIEW DATA FOR PRACTICE
-- ============================================================================

DROP TABLE IF EXISTS hotdog.customer_reviews CASCADE;

CREATE TABLE hotdog.customer_reviews (
    review_id      SERIAL PRIMARY KEY,
    customer_name  VARCHAR(100),
    email          VARCHAR(100),
    phone          VARCHAR(30),
    menu_item_id   INT REFERENCES hotdog.menu_items(menu_item_id),
    rating         INT,
    review_text    TEXT,
    review_date    DATE
);

INSERT INTO hotdog.customer_reviews
    (customer_name, email, phone, menu_item_id, rating, review_text, review_date)
VALUES
    ('John Smith',       'john@email.com',    '210-555-1111',   1, 5, 'Best classic dog in SA!',                '2026-03-20'),
    ('jane doe',         'JANE@EMAIL.COM',    '(210) 555-2222', 2, 4, 'Chili was great but a bit messy',       '2026-03-20'),
    ('BOB JOHNSON',      NULL,                '210.555.3333',   1, NULL, NULL,                                   '2026-03-21'),
    ('  Maria Garcia  ', 'maria@email.com',   NULL,             4, 5, '  Love the veggie dog!   ',             '2026-03-21'),
    ('Carlos Ruiz',      'carlos@email.com',  '210-555-5555',   NULL, 3, 'Good but nothing special',           NULL),
    (NULL,               'mystery@email.com', '210-555-6666',   2, 5, 'AMAZING chili cheese dog!!!',           '2026-03-22'),
    ('lisa WONG',        'Lisa@Email.Com',    '210 555 7777',   5, NULL, '',                                    '2026-03-22'),
    ('Tony Martinez',    'tony@email.com',    '2105558888',     7, 4, 'the works dog is aptly named. so good.','2026-03-23'),
    ('  ANA LOPEZ',      'ANA@email.COM',     NULL,             3, 2, 'turkey dog was   kind of   dry',        '2026-03-23'),
    ('David Kim',        NULL,                NULL,             6, 5, 'Spicy jalapeno dog 10/10',              '2026-03-23'),
    ('sarah  connor',    'sarah@email.com',   '210-555-0000',   NULL, NULL, NULL,                               NULL),
    ('Pat OBrien',       'pat@email.com',     '210-555-1212',   1, 4, 'Classic and reliable. Cant go wrong.',  '2026-03-24');

-- Look at the mess:
SELECT * FROM hotdog.customer_reviews ORDER BY review_id;


-- ============================================================================
-- SECTION 8.2: FINDING NULLs
-- ============================================================================

-- Reviews where the customer didn't give their email:
SELECT review_id, customer_name, email
FROM hotdog.customer_reviews
WHERE email IS NULL;

-- Reviews that DO have a rating:
SELECT review_id, customer_name, rating
FROM hotdog.customer_reviews
WHERE rating IS NOT NULL;


-- ============================================================================
-- SECTION 8.3: COUNTING NULLs — DATA QUALITY CHECK
-- ============================================================================

SELECT
    COUNT(*)                             AS total_rows,
    COUNT(*) - COUNT(customer_name)      AS missing_name,
    COUNT(*) - COUNT(email)              AS missing_email,
    COUNT(*) - COUNT(phone)              AS missing_phone,
    COUNT(*) - COUNT(rating)             AS missing_rating,
    COUNT(*) - COUNT(review_text)        AS missing_review,
    COUNT(*) - COUNT(review_date)        AS missing_date
FROM hotdog.customer_reviews;


-- ============================================================================
-- SECTION 8.4: REPLACING NULLs — COALESCE()
-- ============================================================================

SELECT
    review_id,
    COALESCE(customer_name, 'Anonymous')       AS customer_name,
    COALESCE(email, 'no email provided')       AS email,
    COALESCE(rating, 0)                        AS rating,
    COALESCE(review_text, 'no review written') AS review_text
FROM hotdog.customer_reviews
ORDER BY review_id;


-- ============================================================================
-- SECTION 8.5: EMPTY STRINGS vs NULLs — NULLIF()
-- ============================================================================

-- review_id 3 (Bob) has NULL review_text → is_it_null = TRUE
-- review_id 7 (Lisa) has '' review_text  → is_it_null = FALSE
SELECT review_id, review_text, review_text IS NULL AS is_it_null
FROM hotdog.customer_reviews
WHERE review_id IN (3, 7);

-- Convert '' to NULL, THEN replace with a default:
SELECT
    review_id,
    COALESCE(NULLIF(review_text, ''), 'no review written') AS review_text
FROM hotdog.customer_reviews
ORDER BY review_id;


-- ============================================================================
-- SECTION 8.6: NULLs IN MATH — "NULL IS CONTAGIOUS"
-- ============================================================================

-- NULL * 2 = NULL (not 0!)
SELECT review_id, customer_name, rating, rating * 2 AS doubled
FROM hotdog.customer_reviews
ORDER BY review_id;

-- Fix with COALESCE:
SELECT review_id, customer_name, rating, COALESCE(rating, 0) * 2 AS doubled
FROM hotdog.customer_reviews
ORDER BY review_id;

-- AVG() ignores NULLs automatically:
SELECT
    ROUND(AVG(rating), 2)                    AS avg_ignoring_nulls,
    ROUND(AVG(COALESCE(rating, 0)), 2)       AS avg_treating_nulls_as_zero,
    COUNT(rating)                             AS ratings_counted,
    COUNT(*)                                  AS total_rows
FROM hotdog.customer_reviews;


-- ############################################################################
--
--     PART 9: TEXT CLEANING & DATA STANDARDIZATION
--
-- ############################################################################
--
-- Real-world text data is MESSY. People type things differently:
--   'jane doe', 'BOB JOHNSON', '  Maria Garcia  '
--   'JANE@EMAIL.COM', 'Lisa@Email.Com'
--   '210-555-1111', '(210) 555-2222', '210.555.3333'
--
-- PostgreSQL has built-in functions to fix all of these.
-- ============================================================================


-- ============================================================================
-- SECTION 9.1: CHANGING CASE — UPPER(), LOWER(), INITCAP()
-- ============================================================================

SELECT
    customer_name                  AS original,
    UPPER(customer_name)           AS all_caps,
    LOWER(customer_name)           AS all_lower,
    INITCAP(customer_name)         AS proper_case
FROM hotdog.customer_reviews
WHERE customer_name IS NOT NULL
ORDER BY review_id;

-- INITCAP is usually best for names. LOWER is best for emails.


-- ============================================================================
-- SECTION 9.2: REMOVING EXTRA SPACES — TRIM()
-- ============================================================================

-- See the spaces with markers:
SELECT
    review_id,
    '>' || customer_name || '<'        AS with_spaces,
    '>' || TRIM(customer_name) || '<'  AS trimmed
FROM hotdog.customer_reviews
WHERE customer_name LIKE ' %' OR customer_name LIKE '% '
ORDER BY review_id;


-- ============================================================================
-- SECTION 9.3: COMBINING TRIM + INITCAP (nest functions)
-- ============================================================================

SELECT
    review_id,
    customer_name                      AS original,
    INITCAP(TRIM(customer_name))       AS cleaned
FROM hotdog.customer_reviews
WHERE customer_name IS NOT NULL
ORDER BY review_id;


-- ============================================================================
-- SECTION 9.4: REPLACING TEXT — REPLACE() and REGEXP_REPLACE()
-- ============================================================================

-- Simple phone cleaning: replace dots with dashes
SELECT phone, REPLACE(phone, '.', '-') AS fixed_phone
FROM hotdog.customer_reviews
WHERE phone LIKE '%.%';

-- Strip phone numbers down to just digits using REGEXP_REPLACE:
SELECT
    phone,
    REGEXP_REPLACE(phone, '[^0-9]', '', 'g') AS digits_only
FROM hotdog.customer_reviews
WHERE phone IS NOT NULL
ORDER BY review_id;


-- ============================================================================
-- SECTION 9.5: PUTTING IT ALL TOGETHER — CLEAN THE WHOLE TABLE
-- ============================================================================

SELECT
    reviews.review_id,
    COALESCE(
        INITCAP(TRIM(REGEXP_REPLACE(customer_name, '\s+', ' ', 'g'))),
        'Anonymous'
    )                                                          AS customer_name,
    COALESCE(LOWER(email), 'no email')                         AS email,
    CASE
        WHEN phone IS NULL THEN 'N/A'
        ELSE
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 1 FOR 3)
            || '-' ||
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 4 FOR 3)
            || '-' ||
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 7 FOR 4)
    END                                                        AS phone,
    COALESCE(mi.item_name, 'Not Specified')                    AS item_reviewed,
    COALESCE(reviews.rating, 0)                                AS rating,
    COALESCE(
        NULLIF(TRIM(REGEXP_REPLACE(COALESCE(reviews.review_text, ''), '\s+', ' ', 'g')), ''),
        'No review provided'
    )                                                          AS review_text,
    COALESCE(reviews.review_date, CURRENT_DATE)                AS review_date
FROM hotdog.customer_reviews AS reviews
LEFT JOIN hotdog.menu_items  AS mi ON reviews.menu_item_id = mi.menu_item_id
ORDER BY reviews.review_id;


-- ############################################################################
--
--     PART 10: MATH FUNCTIONS & BUSINESS CALCULATIONS
--
-- ############################################################################
--
-- ARITHMETIC OPERATORS:
--   +  Addition     -  Subtraction    *  Multiplication
--   /  Division     %  Modulo         ^  Exponent
--
-- ROUNDING:
--   ROUND(val, n)  — round to n decimal places
--   TRUNC(val, n)  — chop off decimals (no rounding)
--   CEIL(val)      — round UP to next integer
--   FLOOR(val)     — round DOWN to previous integer
--   ABS(val)       — absolute value (removes negative sign)
--
-- AGGREGATE FUNCTIONS (work across many rows):
--   SUM(col)   AVG(col)   MIN(col)   MAX(col)   COUNT(col)
-- ============================================================================


-- ============================================================================
-- SECTION 10.1: QUICK CALCULATOR MODE
-- ============================================================================

SELECT 10 + 5     AS addition;
SELECT 10.0 / 3   AS decimal_division;   -- use 10.0 not 10 to get decimals!
SELECT 10 / 3     AS integer_division;   -- careful: integer ÷ integer = integer
SELECT 10 % 3     AS remainder;          -- modulo
SELECT ROUND(3.14159, 2) AS rounded;     -- 3.14


-- ============================================================================
-- SECTION 10.2: ARITHMETIC ON TABLE COLUMNS
-- ============================================================================

-- What would each item cost if we doubled the price?
SELECT
    item_name,
    price,
    price * 2 AS double_price
FROM hotdog.menu_items
ORDER BY price;

-- What if we gave a $0.50 discount on every item?
SELECT
    item_name,
    price,
    price - 0.50 AS discounted_price
FROM hotdog.menu_items
ORDER BY price;

-- 10% of each item's price
SELECT
    item_name,
    price,
    ROUND(price * 0.10, 2) AS ten_percent
FROM hotdog.menu_items
ORDER BY price;


-- ============================================================================
-- SECTION 10.3: ROUNDING AND ABS IN PRACTICE
-- ============================================================================

-- How far is each item's price from $5.00?
SELECT
    item_name,
    price,
    ABS(price - 5.00) AS distance_from_five
FROM hotdog.menu_items
ORDER BY distance_from_five;


-- ============================================================================
-- SECTION 10.4: AGGREGATE FUNCTIONS
-- ============================================================================

-- Total revenue from all sales
SELECT SUM(total_amount) AS total_revenue FROM hotdog.sales;

-- Average sale amount
SELECT ROUND(AVG(total_amount), 2) AS avg_sale FROM hotdog.sales;

-- Cheapest and most expensive menu item
SELECT
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive
FROM hotdog.menu_items;

-- Total revenue PER payment type
SELECT
    payment_type,
    COUNT(*)                         AS number_of_sales,
    SUM(total_amount)                AS total_revenue,
    ROUND(AVG(total_amount), 2)      AS avg_per_sale
FROM hotdog.sales
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- Total quantity sold per menu item
SELECT
    mi.item_name,
    SUM(si.quantity)    AS total_qty_sold,
    SUM(si.line_total)  AS total_revenue
FROM hotdog.sale_items AS si
JOIN hotdog.menu_items AS mi ON si.menu_item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY total_revenue DESC;


-- ############################################################################
--
--     PART 11: PUTTING IT ALL TOGETHER — BUSINESS REPORTS
--
-- ############################################################################
--
-- Now we combine EVERYTHING from the lesson: schemas, tables, aliases,
-- joins, bridge tables, NULLs, text cleaning, and math functions to
-- answer real business questions.
-- ============================================================================


-- ============================================================================
-- REPORT 1: SALES TICKET WITH 8.25% TEXAS TAX
-- ============================================================================
-- Scenario: A customer orders 2 Classic Dogs, 1 Chili Cheese Dog,
-- and 1 The Works Dog. Build a receipt with subtotal, tax, and total.

WITH ticket AS (
    SELECT item_name, price, 2 AS qty FROM hotdog.menu_items WHERE item_name = 'Classic Dog'
    UNION ALL
    SELECT item_name, price, 1 AS qty FROM hotdog.menu_items WHERE item_name = 'Chili Cheese Dog'
    UNION ALL
    SELECT item_name, price, 1 AS qty FROM hotdog.menu_items WHERE item_name = 'The Works Dog'
)
SELECT
    item_name,
    qty,
    price                              AS unit_price,
    ROUND(price * qty, 2)              AS line_total
FROM ticket;

-- With subtotal, tax, and grand total:
WITH ticket AS (
    SELECT price, 2 AS qty FROM hotdog.menu_items WHERE item_name = 'Classic Dog'
    UNION ALL
    SELECT price, 1 AS qty FROM hotdog.menu_items WHERE item_name = 'Chili Cheese Dog'
    UNION ALL
    SELECT price, 1 AS qty FROM hotdog.menu_items WHERE item_name = 'The Works Dog'
)
SELECT
    ROUND(SUM(price * qty), 2)              AS subtotal,
    ROUND(SUM(price * qty) * 0.0825, 2)     AS tax_8_25_pct,
    ROUND(SUM(price * qty) * 1.0825, 2)     AS grand_total
FROM ticket;


-- ============================================================================
-- REPORT 2: INVENTORY VALUE
-- ============================================================================
-- How much is all our ingredient stock worth?

SELECT
    ing.ingredient_name,
    inv.quantity                                     AS qty_on_hand,
    ing.unit,
    ing.cost_per_unit,
    ROUND(inv.quantity * ing.cost_per_unit, 2)       AS inventory_value
FROM hotdog.inventory AS inv
JOIN hotdog.ingredients AS ing ON inv.ingredient_id = ing.ingredient_id
ORDER BY inventory_value DESC;

-- Grand total:
SELECT
    COUNT(*)                                                AS total_ingredients,
    ROUND(SUM(inv.quantity * ing.cost_per_unit), 2)         AS total_inventory_value
FROM hotdog.inventory AS inv
JOIN hotdog.ingredients AS ing ON inv.ingredient_id = ing.ingredient_id;


-- ============================================================================
-- REPORT 3: INVENTORY REORDER ALERTS
-- ============================================================================

SELECT
    ing.ingredient_name,
    inv.quantity                                     AS qty_on_hand,
    inv.reorder_level,
    ROUND(inv.quantity * ing.cost_per_unit, 2)       AS inventory_value,
    CASE
        WHEN inv.quantity < inv.reorder_level THEN 'REORDER NOW'
        ELSE 'OK'
    END                                              AS stock_status
FROM hotdog.inventory AS inv
JOIN hotdog.ingredients AS ing ON inv.ingredient_id = ing.ingredient_id
ORDER BY stock_status DESC, inv.quantity;


-- ============================================================================
-- REPORT 4: PROFIT PER MENU ITEM (using the bridge table!)
-- ============================================================================
-- The bridge table (menu_item_ingredients) tells us exactly which
-- ingredients go into each item and how much is used.
-- We can calculate the REAL cost and profit.

SELECT
    mi.item_name,
    mi.price                                                           AS selling_price,
    ROUND(SUM(bridge.quantity_used * ing.cost_per_unit), 2)            AS total_ingredient_cost,
    ROUND(mi.price - SUM(bridge.quantity_used * ing.cost_per_unit), 2) AS profit,
    ROUND(
        (mi.price - SUM(bridge.quantity_used * ing.cost_per_unit))
        / mi.price * 100
    , 1)                                                               AS profit_margin_pct
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items    AS mi  ON bridge.menu_item_id  = mi.menu_item_id
JOIN hotdog.ingredients   AS ing ON bridge.ingredient_id  = ing.ingredient_id
GROUP BY mi.item_name, mi.price
ORDER BY profit_margin_pct DESC;


-- ============================================================================
-- REPORT 5: FULL RECIPE COST WITH VENDOR (4 tables!)
-- ============================================================================

SELECT
    mi.item_name,
    ing.ingredient_name,
    bridge.quantity_used,
    ing.cost_per_unit,
    ROUND(bridge.quantity_used * ing.cost_per_unit, 2) AS ingredient_cost,
    v.vendor_name
FROM hotdog.menu_items                AS mi
JOIN hotdog.menu_item_ingredients     AS bridge ON mi.menu_item_id    = bridge.menu_item_id
JOIN hotdog.ingredients               AS ing    ON bridge.ingredient_id = ing.ingredient_id
JOIN hotdog.vendors                   AS v      ON ing.vendor_id       = v.vendor_id
ORDER BY mi.item_name, ing.ingredient_name;


-- ============================================================================
-- REPORT 6: OWNER PERFORMANCE — REVENUE PER OWNER PER ITEM
-- ============================================================================

SELECT
    o.first_name || ' ' || o.last_name AS owner_name,
    mi.item_name,
    SUM(si.quantity)                   AS total_qty_sold,
    SUM(si.line_total)                 AS total_revenue
FROM hotdog.sales      AS s
JOIN hotdog.owners     AS o   ON s.owner_id      = o.owner_id
JOIN hotdog.sale_items AS si  ON s.sale_id        = si.sale_id
JOIN hotdog.menu_items AS mi  ON si.menu_item_id  = mi.menu_item_id
GROUP BY o.first_name, o.last_name, mi.item_name
ORDER BY owner_name, total_revenue DESC;


-- ============================================================================
-- REPORT 7: COMBO MEAL PROFITABILITY
-- ============================================================================
-- Is a "Classic Dog + Chili Cheese Dog" bundle at $8.00 still profitable?

WITH bundle_items AS (
    SELECT menu_item_id, item_name, price
    FROM hotdog.menu_items
    WHERE item_name IN ('Classic Dog', 'Chili Cheese Dog')
),
bundle_costs AS (
    SELECT
        ROUND(SUM(bridge.quantity_used * ing.cost_per_unit), 2) AS total_ingredient_cost
    FROM hotdog.menu_item_ingredients AS bridge
    JOIN hotdog.ingredients AS ing ON bridge.ingredient_id = ing.ingredient_id
    WHERE bridge.menu_item_id IN (SELECT menu_item_id FROM bundle_items)
)
SELECT
    8.00                                           AS bundle_price,
    (SELECT SUM(price) FROM bundle_items)          AS normal_price,
    bc.total_ingredient_cost,
    ROUND(8.00 - bc.total_ingredient_cost, 2)      AS bundle_profit,
    ROUND(
        (8.00 - bc.total_ingredient_cost) / 8.00 * 100
    , 1)                                           AS bundle_margin_pct,
    ROUND(
        (SELECT SUM(price) FROM bundle_items) - 8.00
    , 2)                                           AS customer_savings
FROM bundle_costs AS bc;


-- ############################################################################
--
--     QUICK REFERENCE — EVERYTHING IN THIS LESSON
--
-- ############################################################################
--
-- SCHEMA:
--   CREATE SCHEMA name;
--   DROP SCHEMA IF EXISTS name CASCADE;
--
-- TABLE:
--   CREATE TABLE schema.table ( columns... );
--   Data types: SERIAL, INT, VARCHAR(n), TEXT, DATE, TIMESTAMP,
--               NUMERIC(p,s), BOOLEAN
--   Constraints: PRIMARY KEY, NOT NULL, REFERENCES, DEFAULT
--
-- DATA LOADING:
--   COPY schema.table (columns) FROM 'path' WITH (FORMAT csv, HEADER true);
--
-- QUERYING:
--   SELECT columns FROM table WHERE condition ORDER BY col LIMIT n;
--
-- TABLE ALIASES:
--   FROM hotdog.sales  AS s     ← "s" = sales
--   JOIN hotdog.owners AS o     ← "o" = owners
--
-- COLUMN ALIASES:
--   SELECT price * 2 AS double_price
--
-- JOIN TYPES:
--   INNER JOIN  → only matching rows from both tables
--   LEFT JOIN   → ALL rows from left + matches from right
--   RIGHT JOIN  → ALL rows from right + matches from left
--   FULL OUTER  → ALL rows from both tables
--
-- BRIDGE TABLE:
--   Connects two tables with a many-to-many relationship.
--   JOIN through it to BOTH parent tables to see names.
--
-- NULL HANDLING:
--   IS NULL / IS NOT NULL       Check for missing values
--   COALESCE(val, default)      Replace NULL with a default
--   NULLIF(val, '')             Turn a value into NULL
--
-- TEXT CLEANING:
--   UPPER(), LOWER(), INITCAP()     Change case
--   TRIM()                          Remove extra spaces
--   REPLACE(text, old, new)         Replace exact text
--   REGEXP_REPLACE(text, pattern, new, 'g')  Replace by pattern
--   '[^0-9]' = not a digit     '\s+' = one or more spaces
--
-- MATH:
--   +  -  *  /  %  ^                Arithmetic operators
--   ROUND(val, n)                   Round to n decimals
--   TRUNC(val, n)                   Truncate (chop, don't round)
--   CEIL() / FLOOR()                Round up / down
--   ABS(val)                        Absolute value
--   SUM() AVG() MIN() MAX() COUNT() Aggregate functions
--
-- ============================================================================
-- END OF LESSON
-- ============================================================================
