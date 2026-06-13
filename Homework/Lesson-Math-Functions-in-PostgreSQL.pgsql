-- Active: 1774905351243@@localhost@5432@student@hotdog
-- ============================================================================
-- LESSON: Mathematical Functions & Calculations in PostgreSQL
-- ============================================================================
-- This lesson covers the math operations and functions available in
-- PostgreSQL. You'll learn:
--
--   PART 1:  Basic Arithmetic Operators
--   PART 2:  Rounding, Truncating, and Absolute Value
--   PART 3:  Power, Square Root, and Logarithms
--   PART 4:  Modulo (Remainder) and Integer Division
--   PART 5:  Aggregate Math Functions (SUM, AVG, MIN, MAX, COUNT)
--   PART 6:  EXAMPLE — Building a Sales Ticket with 8.25% Tax
--   PART 7:  EXAMPLE — Inventory Value (per item and total)
--   PART 8:  EXAMPLE — Using the Bridge Table to Calculate Bundle Profit
--
-- PREREQUISITES:
--   - You must have already run  hotdog-stand-schema.pgsql  so the
--     hotdog schema and all its tables exist with data loaded.
--
-- HOW TO USE THIS FILE:
--   Highlight ONE section at a time and press Ctrl+E (or F5) to run it.
--   Read the comments BEFORE you run each query so you know what to expect.
--   Do NOT run the entire file at once.
-- ============================================================================


-- ############################################################################
--
--                    PART 1: BASIC ARITHMETIC OPERATORS
--
-- ############################################################################
--
-- PostgreSQL supports the standard math operators you already know:
--
--   +   Addition
--   -   Subtraction
--   *   Multiplication
--   /   Division  (integer ÷ integer = integer!  Watch out!)
--   %   Modulo    (remainder after division)
--
-- You can use these on columns in a table, or just do quick math
-- with SELECT (no table needed).
-- ============================================================================


-- ============================================================================
-- SECTION 1.1: QUICK MATH WITH SELECT (no table needed)
-- ============================================================================
-- You can use PostgreSQL like a calculator!
-- Just write SELECT followed by your expression.
-- ============================================================================

-- Addition
SELECT 10 + 5 AS addition_result;            -- 15

-- Subtraction
SELECT 100 - 37 AS subtraction_result;       -- 63

-- Multiplication
SELECT 6 * 7 AS multiplication_result;       -- 42

-- Division (careful — integer ÷ integer = integer, it drops the decimal!)
SELECT 10 / 3 AS integer_division;           -- 3  (not 3.33!)

-- To get a decimal result, make at least ONE number a decimal:
SELECT 10.0 / 3 AS decimal_division;         -- 3.3333333...
SELECT 10 / 3.0 AS also_decimal;             -- 3.3333333...
SELECT CAST(10 AS NUMERIC) / 3 AS cast_way;  -- 3.3333333...

-- Modulo (remainder)
SELECT 10 % 3 AS remainder_result;           -- 1  (10 ÷ 3 = 3 remainder 1)

-- You can combine multiple operations (order of operations applies!)
SELECT 5 + 3 * 2 AS follows_pemdas;          -- 11  (not 16!)
SELECT (5 + 3) * 2 AS use_parentheses;       -- 16


-- ============================================================================
-- SECTION 1.2: ARITHMETIC ON TABLE COLUMNS
-- ============================================================================
-- Here we use real data from the hotdog stand.
-- Let's calculate things using menu item prices.
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

-- What is 10% of each item's price?
SELECT
    item_name,
    price,
    ROUND(price * 0.10, 2) AS ten_percent
FROM hotdog.menu_items
ORDER BY price;


-- ############################################################################
--
--                    PART 2: ROUNDING, TRUNCATING, AND ABSOLUTE VALUE
--
-- ############################################################################
--
-- These functions help you clean up messy decimal results:
--
--   ROUND(value, decimals)  — Rounds to the given number of decimal places
--   TRUNC(value, decimals)  — Chops off decimals (no rounding)
--   CEIL(value)             — Rounds UP to the next whole number
--   FLOOR(value)            — Rounds DOWN to the previous whole number
--   ABS(value)              — Returns the absolute value (removes negative sign)
--
-- ============================================================================


-- ============================================================================
-- SECTION 2.1: ROUNDING
-- ============================================================================

-- ROUND to 2 decimal places (what you'll use most for money)
SELECT ROUND(3.14159, 2) AS rounded;          -- 3.14

-- ROUND to 0 decimal places (nearest whole number)
SELECT ROUND(3.7) AS rounded_whole;            -- 4

-- ROUND with a negative number of places (rounds to tens, hundreds, etc.)
SELECT ROUND(1234.56, -2) AS rounded_hundreds; -- 1200


-- ============================================================================
-- SECTION 2.2: TRUNCATE (chop, don't round)
-- ============================================================================

-- TRUNC just chops off the extra digits — no rounding
SELECT TRUNC(3.789, 2) AS truncated;          -- 3.78  (NOT 3.79)
SELECT TRUNC(3.789, 0) AS truncated_whole;    -- 3     (NOT 4)


-- ============================================================================
-- SECTION 2.3: CEILING(CEIL) AND FLOOR
-- ============================================================================

-- CEILING(CEIL) always rounds UP
SELECT CEIL(4.1)  AS ceiling_result;           -- 5
SELECT CEIL(4.9)  AS ceiling_result2;          -- 5
SELECT CEIL(-2.3) AS ceiling_negative;         -- -2  (toward zero)

-- FLOOR always rounds DOWN
SELECT FLOOR(4.9)  AS floor_result;            -- 4
SELECT FLOOR(4.1)  AS floor_result2;           -- 4
SELECT FLOOR(-2.3) AS floor_negative;          -- -3  (away from zero)


-- ============================================================================
-- SECTION 2.4: ABS (ABSOLUTE VALUE)
-- ============================================================================
-- Removes the negative sign. Useful for finding the distance between numbers.

SELECT ABS(-42)  AS abs_result;                -- 42
SELECT ABS(42)   AS abs_positive;              -- 42
SELECT ABS(-3.5) AS abs_decimal;               -- 3.5

-- Practical example: how far is each item's price from $5.00?
SELECT
    item_name,
    price,
    ABS(price - 5.00) AS distance_from_five
FROM hotdog.menu_items
ORDER BY distance_from_five;


-- ############################################################################
--
--                    PART 3: POWER, SQUARE ROOT, AND LOGARITHMS
--
-- ############################################################################
--
--   POWER(base, exponent)  — Raises base to the exponent (base ^ exponent)
--   SQRT(value)            — Square root
--   CBRT(value)            — Cube root
--   LN(value)              — Natural logarithm (base e)
--   LOG(value)             — Base-10 logarithm
--   LOG(base, value)       — Logarithm with any base
--   EXP(value)             — e raised to the given power (e ^ value)
--   PI()                   — Returns the value of π (3.14159...)
--
-- These show up in statistics, finance, and science calculations.
-- ============================================================================


-- ============================================================================
-- SECTION 3.1: POWER AND ROOTS
-- ============================================================================

-- 2 to the power of 10
SELECT POWER(2, 10) AS two_to_the_tenth;       -- 1024

-- 5 squared
SELECT POWER(5, 2) AS five_squared;            -- 25

-- Square root
SELECT SQRT(144) AS square_root;               -- 12

-- Cube root
SELECT CBRT(27) AS cube_root;                  -- 3

-- You can also use the ^ operator for power
SELECT 2 ^ 10 AS power_operator;               -- 1024


-- ============================================================================
-- SECTION 3.2: LOGARITHMS AND e
-- ============================================================================

-- Natural log (base e)
SELECT LN(2.71828) AS natural_log;             -- ≈ 1.0

-- Base-10 log
SELECT LOG(1000) AS log_base_10;               -- 3  (10^3 = 1000)

-- e raised to a power
SELECT EXP(1) AS e_value;                      -- 2.71828...

-- Pi
SELECT PI() AS pi_value;                       -- 3.14159265358979...


-- ############################################################################
--
--                    PART 4: MODULO AND INTEGER DIVISION
--
-- ############################################################################
--
--   %             — Modulo operator (remainder after division)
--   MOD(a, b)     — Same as a % b (function form)
--   DIV(a, b)     — Integer division (whole number result, no remainder)
--
-- Modulo is useful for things like:
--   - Checking if a number is even or odd  (n % 2 = 0 → even)
--   - Cycling through categories
--   - Distributing items into groups
-- ============================================================================


-- ============================================================================
-- SECTION 4.1: MODULO EXAMPLES
-- ============================================================================

-- 17 divided by 5 = 3 remainder 2
SELECT MOD(17, 5) AS mod_result;               -- 2
SELECT 17 % 5     AS mod_operator;             -- 2

-- Is a number even or odd?
SELECT 10 % 2 AS is_ten_even;                  -- 0 (even!)
SELECT 7  % 2 AS is_seven_even;                -- 1 (odd!)

-- Which menu items have an even-numbered ID?
SELECT menu_item_id, item_name
FROM hotdog.menu_items
WHERE menu_item_id % 2 = 0;


-- ============================================================================
-- SECTION 4.2: INTEGER DIVISION
-- ============================================================================

-- DIV gives you just the whole-number part of the division
SELECT DIV(17, 5) AS int_division;             -- 3  (17 ÷ 5 = 3.4 → just 3)
SELECT DIV(10, 3) AS int_division2;            -- 3


-- ############################################################################
--
--                    PART 5: AGGREGATE MATH FUNCTIONS
--
-- ############################################################################
--
-- Aggregate functions work across MANY rows and return ONE result:
--
--   SUM(column)   — Adds up all values
--   AVG(column)   — Average (mean) of all values
--   MIN(column)   — Smallest value
--   MAX(column)   — Largest value
--   COUNT(column) — Number of non-NULL values
--   COUNT(*)      — Number of rows (including NULLs)
--
-- These are often combined with GROUP BY to get totals per category.
-- ============================================================================


-- ============================================================================
-- SECTION 5.1: SIMPLE AGGREGATES (no GROUP BY)
-- ============================================================================

-- What's the total revenue from all sales?
SELECT SUM(total_amount) AS total_revenue FROM hotdog.sales;

-- What's the average sale amount?
SELECT ROUND(AVG(total_amount), 2) AS avg_sale FROM hotdog.sales;

-- What's the cheapest and most expensive menu item?
SELECT
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive
FROM hotdog.menu_items;

-- How many sales have been made?
SELECT COUNT(*) AS total_sales FROM hotdog.sales;


-- ============================================================================
-- SECTION 5.2: AGGREGATES WITH GROUP BY
-- ============================================================================

-- Total revenue per payment type
SELECT
    payment_type,
    COUNT(*)              AS number_of_sales,
    SUM(total_amount)     AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_per_sale
FROM hotdog.sales
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- Total quantity sold per menu item
SELECT
    mi.item_name,
    SUM(si.quantity)     AS total_qty_sold,
    SUM(si.line_total)   AS total_revenue
FROM hotdog.sale_items si
JOIN hotdog.menu_items mi ON si.menu_item_id = mi.menu_item_id
GROUP BY mi.item_name
ORDER BY total_revenue DESC;


-- ############################################################################
--
--        PART 6: EXAMPLE — BUILDING A SALES TICKET WITH 8.25% TAX
--
-- ############################################################################
--
-- SCENARIO:
-- A customer walks up to the hotdog stand and orders:
--   - 2 Classic Dogs
--   - 1 Chili Cheese Dog
--   - 1 Bottled Water (we'll use The Works Dog as a stand-in)
--
-- We need to build a receipt that shows each line item, a subtotal,
-- the Texas sales tax at 8.25%, and the grand total.
--
-- TAX RATE: 8.25% = 0.0825
-- ============================================================================


-- ============================================================================
-- SECTION 6.1: BUILD THE LINE ITEMS
-- ============================================================================
-- We'll use a CTE (Common Table Expression) to build the ticket step by step.
-- Think of a CTE like a temporary named query you can reference below.
-- ============================================================================

WITH ticket AS (
    -- Define what the customer is ordering
    -- Each row is one line on the receipt
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

-- You should see each item with its quantity, unit price, and line total.


-- ============================================================================
-- SECTION 6.2: ADD SUBTOTAL, TAX, AND GRAND TOTAL
-- ============================================================================
-- Now we calculate everything a real receipt would show.
-- We use TWO CTEs:
--   1. ticket      = the line items
--   2. line_items  = each line with its extended price
-- Then the final SELECT calculates subtotal, tax, and total.
-- ============================================================================

WITH ticket AS (
    SELECT item_name, price, 2 AS qty FROM hotdog.menu_items WHERE item_name = 'Classic Dog'
    UNION ALL
    SELECT item_name, price, 1 AS qty FROM hotdog.menu_items WHERE item_name = 'Chili Cheese Dog'
    UNION ALL
    SELECT item_name, price, 1 AS qty FROM hotdog.menu_items WHERE item_name = 'The Works Dog'
),
line_items AS (
    SELECT
        item_name,
        qty,
        price                    AS unit_price,
        ROUND(price * qty, 2)    AS line_total
    FROM ticket
)
-- Display each line item first
SELECT
    item_name                    AS "Item",
    qty                          AS "Qty",
    TO_CHAR(unit_price, '$9.99') AS "Unit Price",
    TO_CHAR(line_total, '$99.99') AS "Line Total"
FROM line_items

UNION ALL

-- Blank separator line
SELECT '', NULL, '', ''

UNION ALL

-- Subtotal row
SELECT
    'SUBTOTAL',
    NULL,
    '',
    TO_CHAR(SUM(line_total), '$99.99')
FROM line_items

UNION ALL

-- Tax row (8.25%)
SELECT
    'TAX (8.25%)',
    NULL,
    '',
    TO_CHAR(ROUND(SUM(line_total) * 0.0825, 2), '$99.99')
FROM line_items

UNION ALL

-- Grand total row
SELECT
    'TOTAL',
    NULL,
    '',
    TO_CHAR(ROUND(SUM(line_total) * 1.0825, 2), '$99.99')
FROM line_items;

-- ============================================================================
-- KEY MATH USED ON THE TICKET:
--   line_total = price * qty                    (multiplication)
--   subtotal   = SUM(line_total)                (aggregate sum)
--   tax        = subtotal * 0.0825              (percentage as decimal)
--   total      = subtotal * 1.0825              (same as subtotal + tax)
--   ROUND(..., 2)                               (round to 2 decimal places)
--   TO_CHAR(amount, '$99.99')                   (format as dollar amount)
-- ============================================================================


-- ============================================================================
-- SECTION 6.3: A SIMPLER VERSION (just the totals)
-- ============================================================================
-- If you just need the bottom-line numbers, here's a shorter approach.
-- ============================================================================

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


-- ############################################################################
--
--    PART 7: EXAMPLE — INVENTORY VALUE (PER ITEM AND TOTAL)
--
-- ############################################################################
--
-- SCENARIO:
-- The owner wants to know:
--   1. How much of each ingredient is in stock?
--   2. What is the dollar value of each ingredient in inventory?
--   3. What is the TOTAL dollar value of ALL inventory combined?
--
-- FORMULA:
--   inventory_value = quantity_on_hand × cost_per_unit
-- ============================================================================


-- ============================================================================
-- SECTION 7.1: INVENTORY VALUE PER INGREDIENT
-- ============================================================================
-- We JOIN inventory to ingredients to get the name and cost, then multiply.
-- ============================================================================

SELECT
    ing.ingredient_name,
    inv.quantity                                     AS qty_on_hand,
    ing.unit,
    ing.cost_per_unit,
    ROUND(inv.quantity * ing.cost_per_unit, 2)       AS inventory_value
FROM hotdog.inventory inv
JOIN hotdog.ingredients ing ON inv.ingredient_id = ing.ingredient_id
ORDER BY inventory_value DESC;

-- This tells you things like:
--   "We have 200 Beef Franks at $0.75 each = $150.00 worth of Beef Franks"


-- ============================================================================
-- SECTION 7.2: TOTAL INVENTORY VALUE (everything combined)
-- ============================================================================
-- Same query but with SUM to roll it all into one number.
-- ============================================================================

SELECT
    COUNT(*)                                                AS total_ingredients,
    ROUND(SUM(inv.quantity * ing.cost_per_unit), 2)         AS total_inventory_value
FROM hotdog.inventory inv
JOIN hotdog.ingredients ing ON inv.ingredient_id = ing.ingredient_id;

-- This gives you ONE row: the total count of ingredients tracked, and
-- the grand total dollar value of everything in the warehouse.


-- ============================================================================
-- SECTION 7.3: BONUS — FLAG ITEMS BELOW REORDER LEVEL
-- ============================================================================
-- Add a column that says 'REORDER NOW' if quantity is below the threshold.
-- This uses a CASE expression (like an IF statement in SQL).
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
FROM hotdog.inventory inv
JOIN hotdog.ingredients ing ON inv.ingredient_id = ing.ingredient_id
ORDER BY stock_status DESC, inv.quantity;


-- ############################################################################
--
--    PART 8: EXAMPLE — USING THE BRIDGE TABLE TO CALCULATE BUNDLE PROFIT
--
-- ############################################################################
--
-- SCENARIO:
-- The owner wants to know: "Am I actually making money on each menu item?"
--
-- To figure this out we need:
--   menu item PRICE  (what the customer pays)
-- minus
--   COST of all ingredients that go into that item
-- equals
--   PROFIT per item
--
-- The BRIDGE TABLE (menu_item_ingredients) is the key because it tells us
-- exactly which ingredients go into each menu item and how much is used.
--
-- FORMULA:
--   ingredient_cost = quantity_used × cost_per_unit
--   total_cost      = SUM of all ingredient costs for that menu item
--   profit          = price - total_cost
--   profit_margin   = (profit / price) × 100   (as a percentage)
-- ============================================================================


-- ============================================================================
-- SECTION 8.1: INGREDIENT COST BREAKDOWN PER MENU ITEM
-- ============================================================================
-- First, let's see the detailed cost of EACH ingredient in EACH menu item.
-- This uses the bridge table to connect menu_items → ingredients.
-- ============================================================================

SELECT
    mi.item_name,
    ing.ingredient_name,
    bridge.quantity_used,
    ing.cost_per_unit,
    ROUND(bridge.quantity_used * ing.cost_per_unit, 2) AS ingredient_cost
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items    AS mi  ON bridge.menu_item_id  = mi.menu_item_id
JOIN hotdog.ingredients   AS ing ON bridge.ingredient_id  = ing.ingredient_id
ORDER BY mi.item_name, ingredient_cost DESC;

-- You'll see rows like:
--   Classic Dog | Beef Frank | 1.00 | 0.75 | 0.75
--   Classic Dog | Bun        | 1.00 | 0.30 | 0.30
-- These are the individual pieces that add up to the total cost.


-- ============================================================================
-- SECTION 8.2: TOTAL COST AND PROFIT PER MENU ITEM
-- ============================================================================
-- Now we SUM up all the ingredient costs for each menu item and compare
-- that total cost to the selling price.
-- ============================================================================

SELECT
    mi.item_name,
    mi.price                                                          AS selling_price,
    ROUND(SUM(bridge.quantity_used * ing.cost_per_unit), 2)           AS total_ingredient_cost,
    ROUND(mi.price - SUM(bridge.quantity_used * ing.cost_per_unit), 2) AS profit,
    ROUND(
        (mi.price - SUM(bridge.quantity_used * ing.cost_per_unit))
        / mi.price * 100
    , 1)                                                              AS profit_margin_pct
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items    AS mi  ON bridge.menu_item_id  = mi.menu_item_id
JOIN hotdog.ingredients   AS ing ON bridge.ingredient_id  = ing.ingredient_id
GROUP BY mi.item_name, mi.price
ORDER BY profit_margin_pct DESC;

-- You'll see something like:
--   item_name         | selling_price | total_ingredient_cost | profit | profit_margin_pct
--   ------------------+---------------+-----------------------+--------+-------------------
--   Classic Dog       |  3.99         |  1.30                 |  2.69  |  67.4%
--   Chili Cheese Dog  |  5.49         |  2.15                 |  3.34  |  60.8%
--
-- This tells the owner which items are the most profitable!


-- ============================================================================
-- SECTION 8.3: WHICH ITEM MAKES THE MOST MONEY?
-- ============================================================================
-- Same query, but sorted by dollar profit (not percentage).
-- The item with the highest margin % might not bring in the most dollars
-- if it doesn't sell much.
-- ============================================================================

SELECT
    mi.item_name,
    mi.price                                                          AS selling_price,
    ROUND(SUM(bridge.quantity_used * ing.cost_per_unit), 2)           AS total_cost,
    ROUND(mi.price - SUM(bridge.quantity_used * ing.cost_per_unit), 2) AS profit_per_item
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items    AS mi  ON bridge.menu_item_id  = mi.menu_item_id
JOIN hotdog.ingredients   AS ing ON bridge.ingredient_id  = ing.ingredient_id
GROUP BY mi.item_name, mi.price
ORDER BY profit_per_item DESC;


-- ============================================================================
-- SECTION 8.4: BUNDLE EXAMPLE — "COMBO MEAL" PROFIT
-- ============================================================================
-- Say the owner wants to sell a COMBO: Classic Dog + Chili Cheese Dog
-- for a bundle price of $8.00 (normally $3.99 + $5.49 = $9.48).
--
-- Is the bundle still profitable after accounting for ingredient costs?
-- ============================================================================

WITH bundle_items AS (
    -- The two items in the combo
    SELECT menu_item_id, item_name, price
    FROM hotdog.menu_items
    WHERE item_name IN ('Classic Dog', 'Chili Cheese Dog')
),
bundle_costs AS (
    -- Sum up all ingredient costs for those two items combined
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
FROM bundle_costs bc;

-- This shows:
--   bundle_price         = $8.00  (what you charge)
--   normal_price         = $9.48  (what they'd pay buying separately)
--   total_ingredient_cost = cost of all ingredients in both items
--   bundle_profit        = how much the stand makes on the bundle
--   bundle_margin_pct    = profit as a percentage of the bundle price
--   customer_savings     = how much the customer saves vs. buying separately
--
-- KEY INSIGHT: The bridge table (menu_item_ingredients) is what lets us
-- calculate the REAL cost behind any combination of menu items.
-- Without it, we'd only know the selling price — not whether we're
-- actually making or losing money!


-- ############################################################################
--
--                    QUICK REFERENCE — MATH FUNCTIONS
--
-- ############################################################################
--
-- ARITHMETIC OPERATORS:
--   +   Addition            SELECT 5 + 3;
--   -   Subtraction         SELECT 10 - 4;
--   *   Multiplication      SELECT 6 * 7;
--   /   Division            SELECT 10.0 / 3;
--   %   Modulo (remainder)  SELECT 10 % 3;
--   ^   Exponent            SELECT 2 ^ 10;
--
-- ROUNDING & PRECISION:
--   ROUND(val, n)           Round to n decimal places
--   TRUNC(val, n)           Truncate to n decimal places (no rounding)
--   CEIL(val)               Round up to next integer
--   FLOOR(val)              Round down to previous integer
--
-- ABSOLUTE VALUE:
--   ABS(val)                Remove negative sign
--
-- POWERS & ROOTS:
--   POWER(base, exp)        base raised to exp
--   SQRT(val)               Square root
--   CBRT(val)               Cube root
--
-- LOGARITHMS:
--   LN(val)                 Natural log (base e)
--   LOG(val)                Base-10 log
--   LOG(base, val)          Log with any base
--   EXP(val)                e ^ val
--
-- CONSTANTS:
--   PI()                    3.14159265358979...
--
-- AGGREGATES:
--   SUM(col)                Total of all values
--   AVG(col)                Average (mean)
--   MIN(col)                Smallest value
--   MAX(col)                Largest value
--   COUNT(col)              Count of non-NULL values
--   COUNT(*)                Count of all rows
--
-- ============================================================================
