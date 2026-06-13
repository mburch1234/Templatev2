-- ============================================================================
-- HOTDOG STAND DATABASE
-- ============================================================================
-- A complete schema for managing a hotdog stand business including:
--   - Owners, Vendors (suppliers), Ingredients, Inventory
--   - Menu Items, Menu Item Ingredients, Sales, Sale Items
--
-- Run each section one at a time by highlighting the SQL
-- and pressing Ctrl+E (or F5) in PostgreSQL Explorer.
-- ============================================================================


-- ============================================================================
-- STEP 1: CREATE THE SCHEMA
-- ============================================================================
-- This keeps all hotdog stand tables organized in their own namespace.

DROP SCHEMA IF EXISTS hotdog CASCADE;
CREATE SCHEMA hotdog;


-- ============================================================================
-- STEP 2: CREATE TABLES
-- ============================================================================

-- -------------------------------------------------------
-- OWNERS - who owns the hotdog stand(s)
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
-- VENDORS - suppliers who provide ingredients
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
-- INGREDIENTS - individual ingredients (buns, franks, etc.)
-- -------------------------------------------------------
CREATE TABLE hotdog.ingredients (
    ingredient_id   SERIAL PRIMARY KEY,
    ingredient_name VARCHAR(100) NOT NULL,
    unit            VARCHAR(20)  NOT NULL,  -- 'each', 'oz', 'lb', 'bottle'
    cost_per_unit   NUMERIC(8,2) NOT NULL,
    vendor_id       INT REFERENCES hotdog.vendors(vendor_id)
);

-- -------------------------------------------------------
-- INVENTORY - current stock of each ingredient
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
-- MENU_ITEMS - what you can buy (Classic Dog, Chili Dog, etc.)
-- -------------------------------------------------------
CREATE TABLE hotdog.menu_items (
    menu_item_id  SERIAL PRIMARY KEY,
    item_name     VARCHAR(100) NOT NULL,
    description   VARCHAR(255),
    price         NUMERIC(6,2) NOT NULL,
    is_available  BOOLEAN DEFAULT TRUE
);

-- -------------------------------------------------------
-- MENU_ITEM_INGREDIENTS - recipe: which ingredients go in each menu item
-- -------------------------------------------------------
CREATE TABLE hotdog.menu_item_ingredients (
    menu_item_ingredient_id SERIAL PRIMARY KEY,
    menu_item_id   INT NOT NULL REFERENCES hotdog.menu_items(menu_item_id),
    ingredient_id  INT NOT NULL REFERENCES hotdog.ingredients(ingredient_id),
    quantity_used  NUMERIC(8,2) NOT NULL  -- how much of the ingredient per serving
);

-- -------------------------------------------------------
-- SALES - each transaction / order
-- -------------------------------------------------------
CREATE TABLE hotdog.sales (
    sale_id      SERIAL PRIMARY KEY,
    sale_date    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    owner_id     INT REFERENCES hotdog.owners(owner_id),
    total_amount NUMERIC(8,2),
    payment_type VARCHAR(20) DEFAULT 'cash'  -- 'cash', 'card', 'mobile'
);

-- -------------------------------------------------------
-- SALE_ITEMS - line items in each sale
-- -------------------------------------------------------
CREATE TABLE hotdog.sale_items (
    sale_item_id  SERIAL PRIMARY KEY,
    sale_id       INT NOT NULL REFERENCES hotdog.sales(sale_id),
    menu_item_id  INT NOT NULL REFERENCES hotdog.menu_items(menu_item_id),
    quantity      INT NOT NULL DEFAULT 1,
    line_total    NUMERIC(8,2) NOT NULL
);


-- ============================================================================
-- STEP 3: LOAD DATA FROM CSV FILES
-- ============================================================================
-- The CSV files are in the data/hotdog/ folder.
-- IMPORTANT: Run these in ORDER — parent tables first, then child tables.
--
-- The COPY command needs the full path. Adjust if your workspace is different.
-- ============================================================================

-- Load owners
\COPY hotdog.owners (owner_id, first_name, last_name, email, phone) FROM '/workspaces/MS3083_Template_V2/data/hotdog/owners.csv' WITH (FORMAT csv, HEADER true);

-- Load vendors
\COPY hotdog.vendors (vendor_id, vendor_name, contact_name, phone, email, address) FROM '/workspaces/MS3083_Template_V2/data/hotdog/vendors.csv' WITH (FORMAT csv, HEADER true);

-- Load ingredients
\COPY hotdog.ingredients (ingredient_id, ingredient_name, unit, cost_per_unit, vendor_id) FROM '/workspaces/MS3083_Template_V2/data/hotdog/ingredients.csv' WITH (FORMAT csv, HEADER true);

-- Load inventory
\COPY hotdog.inventory (inventory_id, ingredient_id, quantity, reorder_level, last_restocked) FROM '/workspaces/MS3083_Template_V2/data/hotdog/inventory.csv' WITH (FORMAT csv, HEADER true);

-- Load menu items
\COPY hotdog.menu_items (menu_item_id, item_name, description, price, is_available) FROM '/workspaces/MS3083_Template_V2/data/hotdog/menu_items.csv' WITH (FORMAT csv, HEADER true);

-- Load menu item ingredients (recipes)
\COPY hotdog.menu_item_ingredients (menu_item_ingredient_id, menu_item_id, ingredient_id, quantity_used) FROM '/workspaces/MS3083_Template_V2/data/hotdog/menu_item_ingredients.csv' WITH (FORMAT csv, HEADER true);

-- Load sales
\COPY hotdog.sales (sale_id, sale_date, owner_id, total_amount, payment_type) FROM '/workspaces/MS3083_Template_V2/data/hotdog/sales.csv' WITH (FORMAT csv, HEADER true);

-- Load sale items
\COPY hotdog.sale_items (sale_item_id, sale_id, menu_item_id, quantity, line_total) FROM '/workspaces/MS3083_Template_V2/data/hotdog/sale_items.csv' WITH (FORMAT csv, HEADER true);


-- Reset sequences so future INSERTs get the right IDs
SELECT setval('hotdog.owners_owner_id_seq',      (SELECT MAX(owner_id)                  FROM hotdog.owners));
SELECT setval('hotdog.vendors_vendor_id_seq',     (SELECT MAX(vendor_id)                 FROM hotdog.vendors));
SELECT setval('hotdog.ingredients_ingredient_id_seq', (SELECT MAX(ingredient_id)          FROM hotdog.ingredients));
SELECT setval('hotdog.inventory_inventory_id_seq', (SELECT MAX(inventory_id)              FROM hotdog.inventory));
SELECT setval('hotdog.menu_items_menu_item_id_seq', (SELECT MAX(menu_item_id)             FROM hotdog.menu_items));
SELECT setval('hotdog.menu_item_ingredients_menu_item_ingredient_id_seq', (SELECT MAX(menu_item_ingredient_id) FROM hotdog.menu_item_ingredients));
SELECT setval('hotdog.sales_sale_id_seq',         (SELECT MAX(sale_id)                   FROM hotdog.sales));
SELECT setval('hotdog.sale_items_sale_item_id_seq', (SELECT MAX(sale_item_id)             FROM hotdog.sale_items));


-- ============================================================================
-- STEP 4: CHECK / VERIFY THE DATA
-- ============================================================================

-- Quick row counts for every table
SELECT 'owners'               AS table_name, COUNT(*) AS row_count FROM hotdog.owners
UNION ALL
SELECT 'vendors',             COUNT(*) FROM hotdog.vendors
UNION ALL
SELECT 'ingredients',         COUNT(*) FROM hotdog.ingredients
UNION ALL
SELECT 'inventory',           COUNT(*) FROM hotdog.inventory
UNION ALL
SELECT 'menu_items',          COUNT(*) FROM hotdog.menu_items
UNION ALL
SELECT 'menu_item_ingredients', COUNT(*) FROM hotdog.menu_item_ingredients
UNION ALL
SELECT 'sales',               COUNT(*) FROM hotdog.sales
UNION ALL
SELECT 'sale_items',          COUNT(*) FROM hotdog.sale_items
ORDER BY table_name;

-- Preview each table (first 5 rows)
SELECT * FROM hotdog.owners    LIMIT 5;
SELECT * FROM hotdog.vendors   LIMIT 5;
SELECT * FROM hotdog.ingredients LIMIT 5;
SELECT * FROM hotdog.inventory LIMIT 5;
SELECT * FROM hotdog.menu_items LIMIT 5;
SELECT * FROM hotdog.menu_item_ingredients LIMIT 5;
SELECT * FROM hotdog.sales     LIMIT 5;
SELECT * FROM hotdog.sale_items LIMIT 5;


-- ============================================================================
-- STEP 5: USEFUL QUERIES
-- ============================================================================

-- Total sales by payment type
SELECT payment_type, COUNT(*) AS num_sales, SUM(total_amount) AS revenue
FROM hotdog.sales
GROUP BY payment_type
ORDER BY revenue DESC;

-- Best-selling menu items
SELECT mi.item_name, SUM(si.quantity) AS total_sold, SUM(si.line_total) AS total_revenue
FROM hotdog.sale_items si
JOIN hotdog.menu_items mi ON si.menu_item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY total_sold DESC;

-- Ingredients running low (below reorder level)
SELECT i.ingredient_name, inv.quantity, inv.reorder_level
FROM hotdog.inventory inv
JOIN hotdog.ingredients i ON inv.ingredient_id = i.ingredient_id
WHERE inv.quantity < inv.reorder_level
ORDER BY inv.quantity;

-- Cost breakdown per menu item (ingredient costs)
SELECT mi.item_name,
       ing.ingredient_name,
       mii.quantity_used,
       ing.cost_per_unit,
       ROUND(mii.quantity_used * ing.cost_per_unit, 2) AS ingredient_cost
FROM hotdog.menu_item_ingredients mii
JOIN hotdog.menu_items mi  ON mii.menu_item_id  = mi.menu_item_id
JOIN hotdog.ingredients ing ON mii.ingredient_id = ing.ingredient_id
ORDER BY mi.item_name, ing.ingredient_name;
