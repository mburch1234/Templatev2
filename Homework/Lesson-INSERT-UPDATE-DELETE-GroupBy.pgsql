-- ============================================================================
-- LESSON: INSERT, UPDATE, DELETE, and GROUP BY with WHERE & HAVING
-- ============================================================================
-- Using the Mighty Fine Burgers database to demonstrate Data Manipulation
-- Language (DML) commands and aggregate filtering.
--
-- PREREQUISITE: You must have already created and loaded the mightyfine
-- schema (run your homework-mighty-fine-burgers.pgsql first).
--
-- Run each section one at a time by highlighting the SQL
-- and pressing Ctrl+E (or F5) in PostgreSQL Explorer.
-- ============================================================================


-- ============================================================================
-- PART 1: INSERT — Adding New Rows to a Table
-- ============================================================================
-- INSERT adds one or more new rows to a table.
--
-- Syntax:
--   INSERT INTO table_name (column1, column2, ...)
--   VALUES (value1, value2, ...);
--
-- SERIAL columns (like owner_id) auto-number themselves — you can skip them.
-- ============================================================================


-- -------------------------------------------------------
-- 1.1  INSERT a single row
-- -------------------------------------------------------
-- Let's add a new owner to Mighty Fine Burgers.
-- We do NOT need to provide owner_id — it auto-increments.
-- We also skip created_at because it defaults to NOW().

INSERT INTO mightyfine.owners (first_name, last_name, email, phone)
VALUES ('Diana', 'Rojas', 'diana.rojas@mightyfine.com', '512-555-0104');

-- Verify the new row:
SELECT * FROM mightyfine.owners ORDER BY owner_id;
-- You should see owner_id = 4 for Diana Rojas.


-- -------------------------------------------------------
-- 1.2  INSERT multiple rows at once
-- -------------------------------------------------------
-- You can insert several rows in a single statement by comma-separating
-- the VALUE sets. This is more efficient than running INSERT three times.

INSERT INTO mightyfine.menu_items (item_name, description, price, is_available)
VALUES
    ('Onion Rings', 'Crispy battered onion rings', 4.49, TRUE),
    ('Side Salad', 'Fresh garden salad with ranch dressing', 3.99, TRUE),
    ('Mighty Malt Shake', 'Hand-spun vanilla malt shake', 5.99, TRUE);

-- Verify:
SELECT * FROM mightyfine.menu_items ORDER BY menu_item_id;
-- You should now see 14 menu items (11 original + 3 new).


-- -------------------------------------------------------
-- 1.3  INSERT with a subquery (INSERT ... SELECT)
-- -------------------------------------------------------
-- Sometimes you want to copy or derive rows from existing data.
-- Let's add a new sale for our new owner Diana (owner_id = 4).

INSERT INTO mightyfine.sales (sale_date, owner_id, total_amount, payment_type)
VALUES ('2026-04-01 12:00:00', 4, 16.47, 'card');

-- Now add the sale items for that sale.
-- We need the sale_id that was just created. We can grab it:
-- (In practice you'd use RETURNING or currval — we'll peek at it first.)

SELECT MAX(sale_id) AS new_sale_id FROM mightyfine.sales;
-- Let's say this returns 26. We'll use 26 below.
-- NOTE: If yours is different, adjust the number.

INSERT INTO mightyfine.sale_items (sale_id, menu_item_id, quantity, line_total)
VALUES
    (26, 1, 1, 7.99),   -- 1 Classic Burger
    (26, 8, 1, 3.99),   -- 1 Mighty Fine Fries
    (26, 9, 1, 5.49);   -- 1 Chocolate Shake
-- (7.99 + 3.99 + 5.49 = 17.47... close to our total — pretax!)

-- Verify:
SELECT s.sale_id, s.sale_date, o.first_name, o.last_name, s.total_amount
FROM mightyfine.sales s
JOIN mightyfine.owners o ON s.owner_id = o.owner_id
WHERE o.first_name = 'Diana';


-- -------------------------------------------------------
-- 1.4  INSERT with RETURNING
-- -------------------------------------------------------
-- RETURNING gives you back the inserted row immediately — very useful
-- for getting the auto-generated ID without a second query.

INSERT INTO mightyfine.vendors (vendor_name, contact_name, phone, email, address)
VALUES ('Southside Spice Co', 'Maria Gonzalez', '512-555-3001',
        'maria@southsidespice.com', '500 S Congress Ave Austin TX')
RETURNING vendor_id, vendor_name;
-- This returns the new vendor_id right away!


-- ============================================================================
-- PART 2: UPDATE — Modifying Existing Rows
-- ============================================================================
-- UPDATE changes values in rows that already exist.
--
-- Syntax:
--   UPDATE table_name
--   SET column1 = new_value1, column2 = new_value2
--   WHERE condition;
--
-- *** ALWAYS include a WHERE clause! ***
-- Without WHERE, UPDATE changes EVERY row in the table!
-- ============================================================================


-- -------------------------------------------------------
-- 2.1  UPDATE a single row
-- -------------------------------------------------------
-- Fountain Drink price goes up from $2.49 to $2.99.

-- First, look at the current value:
SELECT menu_item_id, item_name, price
FROM mightyfine.menu_items
WHERE item_name = 'Fountain Drink';

-- Now update it:
UPDATE mightyfine.menu_items
SET price = 2.99
WHERE item_name = 'Fountain Drink';

-- Verify the change:
SELECT menu_item_id, item_name, price
FROM mightyfine.menu_items
WHERE item_name = 'Fountain Drink';
-- price should now be 2.99


-- -------------------------------------------------------
-- 2.2  UPDATE multiple columns at once
-- -------------------------------------------------------
-- The Veggie Burger gets a new description AND a price increase.

UPDATE mightyfine.menu_items
SET description = 'Impossible patty on brioche bun with avocado, lettuce, tomato',
    price = 9.49
WHERE item_name = 'Veggie Burger';

-- Verify:
SELECT item_name, description, price
FROM mightyfine.menu_items
WHERE item_name = 'Veggie Burger';


-- -------------------------------------------------------
-- 2.3  UPDATE multiple rows with a condition
-- -------------------------------------------------------
-- All items priced under $4.00 get a 10% price increase.

-- First, see which items will be affected:
SELECT item_name, price
FROM mightyfine.menu_items
WHERE price < 4.00;

-- Now apply the increase:
UPDATE mightyfine.menu_items
SET price = ROUND(price * 1.10, 2)
WHERE price < 4.00;

-- Verify:
SELECT item_name, price
FROM mightyfine.menu_items
WHERE price < 5.00
ORDER BY price;


-- -------------------------------------------------------
-- 2.4  UPDATE with a calculation from another table
-- -------------------------------------------------------
-- Let's update inventory — restock all ingredients from vendor 3
-- (Austin Fresh Produce) by adding 50 units.

-- Before:
SELECT i.ingredient_name, inv.quantity
FROM mightyfine.inventory inv
JOIN mightyfine.ingredients i ON inv.ingredient_id = i.ingredient_id
WHERE i.vendor_id = 3;

-- Update:
UPDATE mightyfine.inventory
SET quantity = quantity + 50,
    last_restocked = CURRENT_DATE
WHERE ingredient_id IN (
    SELECT ingredient_id
    FROM mightyfine.ingredients
    WHERE vendor_id = 3
);

-- After:
SELECT i.ingredient_name, inv.quantity, inv.last_restocked
FROM mightyfine.inventory inv
JOIN mightyfine.ingredients i ON inv.ingredient_id = i.ingredient_id
WHERE i.vendor_id = 3;


-- ============================================================================
-- PART 3: DELETE — Removing Rows from a Table
-- ============================================================================
-- DELETE removes rows from a table.
--
-- Syntax:
--   DELETE FROM table_name
--   WHERE condition;
--
-- *** ALWAYS include a WHERE clause! ***
-- Without WHERE, DELETE removes EVERY row!
--
-- IMPORTANT: You cannot delete a row if another table's foreign key
-- references it. You must delete the child rows first.
-- ============================================================================


-- -------------------------------------------------------
-- 3.1  DELETE a single row
-- -------------------------------------------------------
-- Remove the Bottled Water from the menu.
-- First check if it has been sold (child rows in sale_items):

SELECT si.sale_item_id, mi.item_name
FROM mightyfine.sale_items si
JOIN mightyfine.menu_items mi ON si.menu_item_id = mi.menu_item_id
WHERE mi.item_name = 'Bottled Water';

-- If there ARE sale_items referencing Bottled Water, we must delete those first:
DELETE FROM mightyfine.sale_items
WHERE menu_item_id = (
    SELECT menu_item_id FROM mightyfine.menu_items
    WHERE item_name = 'Bottled Water'
);

-- Also remove any bridge-table rows (recipes):
DELETE FROM mightyfine.menu_item_ingredients
WHERE menu_item_id = (
    SELECT menu_item_id FROM mightyfine.menu_items
    WHERE item_name = 'Bottled Water'
);

-- NOW we can safely delete the menu item itself:
DELETE FROM mightyfine.menu_items
WHERE item_name = 'Bottled Water';

-- Verify it's gone:
SELECT * FROM mightyfine.menu_items ORDER BY menu_item_id;


-- -------------------------------------------------------
-- 3.2  DELETE with a condition (multiple rows)
-- -------------------------------------------------------
-- Remove all sales that were paid with 'mobile' payment.
-- We must remove child rows (sale_items) first!

-- See which sales are mobile:
SELECT sale_id, total_amount, payment_type
FROM mightyfine.sales
WHERE payment_type = 'mobile';

-- Delete the sale_items for those sales:
DELETE FROM mightyfine.sale_items
WHERE sale_id IN (
    SELECT sale_id FROM mightyfine.sales
    WHERE payment_type = 'mobile'
);

-- Now delete the sales themselves:
DELETE FROM mightyfine.sales
WHERE payment_type = 'mobile';

-- Verify:
SELECT DISTINCT payment_type FROM mightyfine.sales;
-- 'mobile' should no longer appear.


-- -------------------------------------------------------
-- 3.3  DELETE with RETURNING (see what you removed)
-- -------------------------------------------------------
-- Remove the new menu items we added earlier and see what was deleted.

DELETE FROM mightyfine.menu_items
WHERE item_name IN ('Onion Rings', 'Side Salad', 'Mighty Malt Shake')
RETURNING menu_item_id, item_name, price;
-- This shows you exactly which rows were removed.


-- ============================================================================
-- PART 4: GROUP BY with WHERE and HAVING
-- ============================================================================
-- GROUP BY collapses rows into groups and lets you run aggregate functions
-- (COUNT, SUM, AVG, MIN, MAX) on each group.
--
-- WHERE vs HAVING:
--   WHERE  filters individual rows   BEFORE grouping
--   HAVING filters grouped results   AFTER  grouping
--
-- Execution order:
--   FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
--
-- Rule of thumb:
--   - If you're filtering on a raw column value → use WHERE
--   - If you're filtering on an aggregate (COUNT, SUM, AVG) → use HAVING
-- ============================================================================


-- -------------------------------------------------------
-- 4.1  Simple GROUP BY — count of sales by payment type
-- -------------------------------------------------------
SELECT payment_type,
       COUNT(*) AS num_sales,
       SUM(total_amount) AS total_revenue
FROM mightyfine.sales
GROUP BY payment_type
ORDER BY total_revenue DESC;
-- Shows how many sales and total $ for each payment method.


-- -------------------------------------------------------
-- 4.2  GROUP BY with WHERE — filter rows BEFORE grouping
-- -------------------------------------------------------
-- Total revenue per owner, but ONLY for CARD sales.
-- WHERE filters individual sale rows before they are grouped.

SELECT o.first_name || ' ' || o.last_name AS owner_name,
       COUNT(*) AS card_sales,
       SUM(s.total_amount) AS card_revenue
FROM mightyfine.sales s
JOIN mightyfine.owners o ON s.owner_id = o.owner_id
WHERE s.payment_type = 'card'                -- filters BEFORE grouping
GROUP BY o.first_name, o.last_name
ORDER BY card_revenue DESC;


-- -------------------------------------------------------
-- 4.3  GROUP BY with HAVING — filter groups AFTER grouping
-- -------------------------------------------------------
-- Show menu items that have been sold MORE THAN 3 times total.
-- We can't use WHERE for this because "total quantity sold" is an aggregate.

SELECT mi.item_name,
       SUM(si.quantity) AS total_qty_sold
FROM mightyfine.sale_items si
JOIN mightyfine.menu_items mi ON si.menu_item_id = mi.menu_item_id
GROUP BY mi.item_name
HAVING SUM(si.quantity) > 3                  -- filters AFTER grouping
ORDER BY total_qty_sold DESC;


-- -------------------------------------------------------
-- 4.4  GROUP BY with WHERE *and* HAVING together
-- -------------------------------------------------------
-- Among CARD sales only (WHERE), show owners who have more than
-- $20 in total card revenue (HAVING).
--
-- Think of it as a two-stage filter:
--   1. WHERE removes non-card sales (row-level filter)
--   2. GROUP BY groups the remaining rows by owner
--   3. HAVING removes owners whose card total is <= $20

SELECT o.first_name || ' ' || o.last_name AS owner_name,
       COUNT(*) AS card_sales,
       SUM(s.total_amount) AS card_revenue
FROM mightyfine.sales s
JOIN mightyfine.owners o ON s.owner_id = o.owner_id
WHERE s.payment_type = 'card'                -- Stage 1: only card sales
GROUP BY o.first_name, o.last_name
HAVING SUM(s.total_amount) > 20              -- Stage 2: only big earners
ORDER BY card_revenue DESC;


-- -------------------------------------------------------
-- 4.5  GROUP BY with multiple aggregates
-- -------------------------------------------------------
-- Revenue summary per day: count of sales, total revenue,
-- average sale, and the single largest sale that day.

SELECT DATE(sale_date) AS sale_day,
       COUNT(*) AS num_sales,
       SUM(total_amount) AS daily_revenue,
       ROUND(AVG(total_amount), 2) AS avg_sale,
       MAX(total_amount) AS largest_sale
FROM mightyfine.sales
GROUP BY DATE(sale_date)
ORDER BY sale_day;


-- -------------------------------------------------------
-- 4.6  HAVING with COUNT — vendors supplying many ingredients
-- -------------------------------------------------------
-- Show only vendors who supply MORE THAN 3 ingredients.

SELECT v.vendor_name,
       COUNT(*) AS num_ingredients
FROM mightyfine.ingredients i
JOIN mightyfine.vendors v ON i.vendor_id = v.vendor_id
GROUP BY v.vendor_name
HAVING COUNT(*) > 3
ORDER BY num_ingredients DESC;


-- -------------------------------------------------------
-- 4.7  HAVING with AVG — pricey ingredient categories
-- -------------------------------------------------------
-- Show vendors whose average ingredient cost is above $0.50.

SELECT v.vendor_name,
       COUNT(*) AS num_ingredients,
       ROUND(AVG(i.cost_per_unit), 2) AS avg_cost
FROM mightyfine.ingredients i
JOIN mightyfine.vendors v ON i.vendor_id = v.vendor_id
GROUP BY v.vendor_name
HAVING AVG(i.cost_per_unit) > 0.50
ORDER BY avg_cost DESC;


-- ============================================================================
-- QUICK REFERENCE CHEAT SHEET
-- ============================================================================
--
-- INSERT INTO table (cols) VALUES (vals);          -- add rows
-- INSERT INTO table (cols) VALUES (v1), (v2);      -- add multiple rows
-- INSERT INTO table (cols) SELECT ... FROM ...;    -- insert from query
--
-- UPDATE table SET col = val WHERE condition;      -- change existing rows
--   *** Always use WHERE or you change everything! ***
--
-- DELETE FROM table WHERE condition;               -- remove rows
--   *** Always use WHERE or you delete everything! ***
--   *** Delete child rows before parent rows (foreign keys) ***
--
-- SELECT cols FROM table
--   WHERE row_filter          -- filters rows BEFORE grouping
--   GROUP BY cols             -- collapse into groups
--   HAVING aggregate_filter   -- filters groups AFTER grouping
--   ORDER BY cols;
--
-- WHERE  = filters raw column values (before GROUP BY)
-- HAVING = filters aggregate results (after GROUP BY)
-- ============================================================================
