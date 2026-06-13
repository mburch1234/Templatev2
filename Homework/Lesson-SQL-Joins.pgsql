-- Active: 1774905351243@@localhost@5432@student@hotdog
-- ============================================================================
-- LESSON: SQL Joins — Combining Tables
-- ============================================================================
-- So far you've been working with ONE table at a time. In this lesson
-- we learn how to pull data from TWO (or more) tables at once using JOINs.
-- Don't worry — the idea is simpler than it sounds, and we'll take it
-- one step at a time using our Hotdog Stand database.
--
-- Here's what we'll cover:
--
--   PART 1:  Why We Need Joins (The Big Picture)
--   PART 2:  Table Aliases — Giving Tables Nicknames
--   PART 3:  INNER JOIN — Only the Overlap
--   PART 4:  LEFT (OUTER) JOIN — Keep Everything on the Left
--   PART 5:  RIGHT (OUTER) JOIN — Keep Everything on the Right
--   PART 6:  FULL OUTER JOIN — Keep Everything from Both Sides
--   PART 7:  SEMI JOIN — "Does a Match Exist?"
--   PART 8:  ANTI JOIN — "Where is There NO Match?"
--   PART 9:  Joining Multiple Tables (3+ Table Joins)
--   PART 10: Key Takeaways & Cheat Sheet
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
--                    PART 1: WHY WE NEED JOINS
--
-- ############################################################################
--
-- WHY IS DATA IN SEPARATE TABLES?
-- --------------------------------
-- Databases keep different kinds of information in separate tables.
-- Our hotdog stand has one table for OWNERS, another for SALES,
-- another for MENU ITEMS, and so on. This avoids repeating the same
-- info over and over (like typing "Tony Martinez" in every single
-- sale row).
--
-- The trade-off is that when you need to answer a question, the
-- pieces you need live in DIFFERENT tables.
--
-- REAL-WORLD ANALOGY:
--   Imagine the hotdog stand keeps separate notebooks:
--     📓 Notebook 1 — "Owners" (who runs the stand each shift)
--     📓 Notebook 2 — "Sales"  (each transaction that happened)
--     📓 Notebook 3 — "Menu"   (what items we sell and their prices)
--
--   A customer asks: "Who sold me that Chili Dog at noon?"
--   To answer, you'd flip between notebooks and match up the info.
--   That's exactly what a JOIN does — it lines up rows from two
--   (or more) tables based on a column they share (usually an ID).
--
-- OUR HOTDOG STAND TABLES:
--
--   owners ──────────┐
--                     ├──► sales ──────► sale_items ──► menu_items
--   vendors ──► ingredients ──► inventory
--                     │
--                     └──► menu_item_ingredients
--
-- The arrows show how tables connect through shared ID columns
-- (called foreign keys). JOINs let us follow those arrows.
-- ============================================================================

-- Let's look at what we're working with:
SELECT * FROM hotdog.owners;
SELECT * FROM hotdog.sales     ORDER BY sale_id LIMIT 10;
SELECT * FROM hotdog.menu_items;


-- ############################################################################
--
--                    PART 2: TABLE ALIASES — GIVING TABLES NICKNAMES
--
-- ############################################################################
--
-- Before we start joining tables, we need ONE quick concept: aliases.
--
-- WHAT'S THE PROBLEM?
--   When you join two tables, they might both have a column with the
--   SAME name. For example, both "owners" and "sales" have a column
--   called "created_at". If you write SELECT created_at, SQL won't
--   know which table you mean — and it will give you an error.
--
-- THE FIX: Give each table a short NICKNAME (called an "alias").
--
-- SYNTAX:
--   FROM  hotdog.sales  AS  s       ← "s" is now a nickname for sales
--   JOIN  hotdog.owners AS  o       ← "o" is now a nickname for owners
--
-- Then use the nickname before each column to be specific:
--   s.sale_id,  s.total_amount       ← these come from the sales table
--   o.first_name, o.last_name        ← these come from the owners table
--
-- REAL-WORLD ANALOGY:
--   Imagine you have two friends both named "Tony":
--     Tony M. → the owner who works the morning shift
--     Tony R. → a regular customer
--   You add the initial so people know which Tony you're talking about.
--   Table aliases work the same way — they tell SQL which table you mean.
--
-- RULES (don't overthink these — they're simple):
--   - Pick a short abbreviation: first letter(s) of the table name.
--   - The AS keyword is optional ( FROM hotdog.sales s ) works too.
--   - Once you give a table an alias, use that alias for ALL its columns.
--
-- ============================================================================

-- WITHOUT aliases — works here because column names happen to be unique:
SELECT sale_id, sale_date, total_amount
FROM hotdog.sales
LIMIT 5;

-- WITH aliases — REQUIRED when joining because both tables have columns
-- like created_at, and we need to tell SQL which table we mean:
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


-- ############################################################################
--
--                    PART 3: INNER JOIN — ONLY THE OVERLAP
--
-- ############################################################################
--
-- An INNER JOIN is the most common type of join. It returns ONLY
-- the rows where BOTH tables have a matching value. If a row in one
-- table has no partner in the other table, it gets left out.
--
-- PICTURE IT LIKE A VENN DIAGRAM:
--
--      ┌───────────┐   ┌───────────┐
--      │  Table A   │   │  Table B   │
--      │           ┌┼───┼┐          │
--      │           │INNER│          │
--      │           │JOIN │          │
--      │           └┼───┼┘          │
--      └───────────┘   └───────────┘
--                ▲▲▲▲▲▲▲
--            Only the overlap
--
-- REAL-WORLD ANALOGY:
--   You have a stack of RECEIPTS (sales) and a list of EMPLOYEES (owners).
--   You lay them side by side and only keep the receipts where you can
--   find the matching employee. If a receipt has an unknown employee
--   number, you set it aside — it doesn't make the cut.
--
-- SYNTAX:
--   SELECT columns
--   FROM table_a AS a
--   INNER JOIN table_b AS b  ON a.key = b.key;
--
-- GOOD TO KNOW: Writing just "JOIN" is the same as "INNER JOIN".
-- We'll use both in this lesson so you get comfortable with either.
-- ============================================================================


-- ============================================================================
-- SECTION 3.1: BASIC INNER JOIN — SALES + OWNERS
-- ============================================================================
-- Question: "Who was working when each sale was made?"
-- We need data from TWO tables:
--   sales  → has the sale_date, total_amount, and owner_id
--   owners → has the first_name and last_name for that owner_id
-- ============================================================================

SELECT
    s.sale_id,
    s.sale_date,
    o.first_name || ' ' || o.last_name AS owner_name,
    s.total_amount,
    s.payment_type
FROM hotdog.sales  AS s
INNER JOIN hotdog.owners AS o  ON s.owner_id = o.owner_id
ORDER BY s.sale_id;

-- Every sale here has a matching owner. The ON clause is the key part:
--   ON s.owner_id = o.owner_id
-- This tells SQL: "Line up each sale with the owner who has the SAME
-- owner_id."  Think of it like looking up an employee number on a
-- receipt and finding that person in the employee list.


-- ============================================================================
-- SECTION 3.2: INNER JOIN — SALE ITEMS + MENU ITEMS
-- ============================================================================
-- Question: "What items were sold and at what price?"
-- sale_items has the quantity and line_total, but the ITEM NAME
-- lives in menu_items. We join them on menu_item_id.
-- ============================================================================

SELECT
    si.sale_item_id,
    si.sale_id,
    mi.item_name,
    mi.price       AS menu_price,
    si.quantity,
    si.line_total
FROM hotdog.sale_items AS si
INNER JOIN hotdog.menu_items AS mi  ON si.menu_item_id = mi.menu_item_id
ORDER BY si.sale_id, si.sale_item_id;

-- "si" is our nickname for sale_items, "mi" for menu_items.
-- The result shows what was actually ordered, with the item name
-- pulled from the menu_items table.


-- ============================================================================
-- SECTION 3.3: INNER JOIN — INGREDIENTS + VENDORS
-- ============================================================================
-- Question: "Which vendor supplies each ingredient?"
-- The ingredient table has vendor_id, but to see the vendor NAME
-- we need to join to the vendors table.
-- ============================================================================

SELECT
    i.ingredient_name,
    i.cost_per_unit,
    i.unit,
    v.vendor_name,
    v.contact_name,
    v.phone AS vendor_phone
FROM hotdog.ingredients AS i
INNER JOIN hotdog.vendors AS v  ON i.vendor_id = v.vendor_id
ORDER BY v.vendor_name, i.ingredient_name;

-- "i" = ingredients, "v" = vendors.
-- This shows us the full supply chain — who supplies what.


-- ############################################################################
--
--                    PART 4: LEFT (OUTER) JOIN — KEEP EVERYTHING ON THE LEFT
--
-- ############################################################################
--
-- A LEFT JOIN keeps ALL rows from the LEFT table (the one after FROM),
-- and tries to find matching rows from the RIGHT table (the one after JOIN).
-- If there's no match for a row, the right-side columns just say NULL
-- (which means "no data").
--
-- THE KEY DIFFERENCE FROM INNER JOIN:
--   INNER JOIN → throws away rows that don't match
--   LEFT JOIN  → keeps every row from the left table no matter what
--
-- PICTURE IT LIKE A VENN DIAGRAM:
-- VENN DIAGRAM:
--
--      ┌───────────┐   ┌───────────┐
--      │ ■■■■■■■■■ │   │  Table B   │
--      │ ■■■■■■■■┌┼───┼┐          │
--      │ ■■■■■■■■│LEFT│          │
--      │ ■■■■■■■■│JOIN│          │
--      │ ■■■■■■■■└┼───┼┘          │
--      └───────────┘   └───────────┘
--      ▲▲▲▲▲▲▲▲▲▲▲▲
--      ALL of Table A + matches from B
--
-- REAL-WORLD ANALOGY:
--   You print out a list of EVERY item on the menu and then check
--   the receipt pile to see which items have actually been sold.
--   - Items that have been sold? You write down their sales info.
--   - Items that HAVEN'T been sold? They stay on the list, but the
--     sales column is blank (NULL). Nobody ordered them.
--   LEFT JOIN keeps the full list — nothing gets thrown away.
--
-- WHY IS THIS USEFUL?
--   - Find what's MISSING (items never sold, owners with no shifts)
--   - Build complete reports that include zeros
--   - Avoid accidentally losing data
--
-- SYNTAX:
--   SELECT columns
--   FROM table_a AS a
--   LEFT JOIN table_b AS b  ON a.key = b.key;
-- ============================================================================


-- ============================================================================
-- SECTION 4.1: LEFT JOIN — ALL MENU ITEMS, EVEN UNSOLD ONES
-- ============================================================================
-- First let's set up a scenario. We'll add a new menu item that has
-- never been sold, so we can see the difference between INNER and LEFT.
-- ============================================================================

-- Add a brand new menu item that nobody has ordered yet:
INSERT INTO hotdog.menu_items (item_name, description, price, is_available)
VALUES ('Fiesta Dog', 'Beef frank with pico de gallo, guacamole, and lime crema', 6.50, TRUE)
ON CONFLICT DO NOTHING;

-- INNER JOIN — the Fiesta Dog DISAPPEARS because it has no sales!
SELECT
    mi.item_name,
    COUNT(si.sale_item_id) AS times_sold
FROM hotdog.menu_items AS mi
INNER JOIN hotdog.sale_items AS si  ON mi.menu_item_id = si.menu_item_id
GROUP BY mi.item_name
ORDER BY times_sold DESC;
-- Notice: Fiesta Dog is NOT in the results. It has zero sales,
-- so INNER JOIN has nothing to match it with and drops it.

-- LEFT JOIN — Fiesta Dog STAYS with a count of 0!
SELECT
    mi.item_name,
    COUNT(si.sale_item_id) AS times_sold
FROM hotdog.menu_items AS mi
LEFT JOIN hotdog.sale_items AS si  ON mi.menu_item_id = si.menu_item_id
GROUP BY mi.item_name
ORDER BY times_sold DESC;
-- Now Fiesta Dog appears with 0 sales. LEFT JOIN kept it because it
-- keeps ALL rows from the left table (menu_items), even without a match.


-- ============================================================================
-- SECTION 4.2: LEFT JOIN — FIND ALL OWNERS AND THEIR SALES
-- ============================================================================
-- Question: "Show all owners and how much revenue they've generated."
-- Some owners might not have any sales recorded yet.
-- ============================================================================

SELECT
    o.first_name || ' ' || o.last_name AS owner_name,
    COUNT(s.sale_id)    AS number_of_sales,
    COALESCE(SUM(s.total_amount), 0) AS total_revenue
FROM hotdog.owners AS o
LEFT JOIN hotdog.sales AS s  ON o.owner_id = s.owner_id
GROUP BY o.owner_id, o.first_name, o.last_name
ORDER BY total_revenue DESC;

-- "o" = owners (LEFT table — we keep ALL owners),
-- "s" = sales  (RIGHT table — matched where possible).
-- COALESCE replaces NULL sums with 0 for owners who had no sales.


-- ============================================================================
-- SECTION 4.3: LEFT JOIN — FIND INGREDIENTS WITH NO INVENTORY RECORD
-- ============================================================================
-- Maybe someone added a new ingredient but forgot to set up its inventory.
-- LEFT JOIN + WHERE ... IS NULL is a classic pattern to find orphan records.
-- ============================================================================

SELECT
    i.ingredient_name,
    i.cost_per_unit,
    inv.quantity,
    inv.reorder_level
FROM hotdog.ingredients AS i
LEFT JOIN hotdog.inventory AS inv  ON i.ingredient_id = inv.ingredient_id
ORDER BY i.ingredient_name;

-- If any ingredient has NULL for quantity and reorder_level, it means
-- there's no inventory record for it — someone forgot to add one!


-- ############################################################################
--
--                    PART 5: RIGHT (OUTER) JOIN — KEEP EVERYTHING ON THE RIGHT
--
-- ############################################################################
--
-- A RIGHT JOIN is just a LEFT JOIN flipped around.
-- It keeps ALL rows from the RIGHT table (the one after JOIN),
-- and matches what it can from the LEFT table (the one after FROM).
-- Unmatched rows on the left side show NULL.
--
-- VENN DIAGRAM:
--
--      ┌───────────┐   ┌───────────┐
--      │  Table A   │   │ ■■■■■■■■■ │
--      │           ┌┼───┼┐■■■■■■■■ │
--      │           │RGHT│■■■■■■■■ │
--      │           │JOIN│■■■■■■■■ │
--      │           └┼───┼┘■■■■■■■■ │
--      └───────────┘   └───────────┘
--                       ▲▲▲▲▲▲▲▲▲▲▲
--                ALL of Table B + matches from A
--
-- REAL-WORLD ANALOGY:
--   Same idea as LEFT JOIN, just flipped. You're saying:
--   "I want EVERY row from the RIGHT table, and attach whatever
--    matches from the left. If the left has nothing, fill with NULL."
--
-- HONEST TRUTH:
--   In practice, almost everyone just uses LEFT JOIN and switches
--   which table comes first. But you should know RIGHT JOIN exists
--   because you'll see it on exams and in other people's code.
--   If you can do LEFT JOIN, you already understand RIGHT JOIN
--   — it's the same logic, just reversed.
--
-- SYNTAX:
--   SELECT columns
--   FROM table_a AS a
--   RIGHT JOIN table_b AS b  ON a.key = b.key;
-- ============================================================================


-- ============================================================================
-- SECTION 5.1: RIGHT JOIN — ALL VENDORS, EVEN THOSE WITH NO INGREDIENTS
-- ============================================================================
-- Let's add a vendor who doesn't supply any ingredients yet.
-- ============================================================================

-- Add a new vendor with no ingredients:
INSERT INTO hotdog.vendors (vendor_name, contact_name, phone, email, address)
VALUES ('San Antonio Spice Co', 'Ray Ramirez', '210-555-9999', 'ray@saspice.com', '500 Riverwalk San Antonio TX')
ON CONFLICT DO NOTHING;

-- RIGHT JOIN — keeps ALL vendors, even San Antonio Spice Co
SELECT
    i.ingredient_name,
    i.cost_per_unit,
    v.vendor_name,
    v.contact_name
FROM hotdog.ingredients AS i
RIGHT JOIN hotdog.vendors AS v  ON i.vendor_id = v.vendor_id
ORDER BY v.vendor_name, i.ingredient_name;

-- "San Antonio Spice Co" appears with NULLs for ingredient columns
-- because no ingredient references this vendor yet.

-- THE SAME RESULT using LEFT JOIN (just flip the table order):
SELECT
    i.ingredient_name,
    i.cost_per_unit,
    v.vendor_name,
    v.contact_name
FROM hotdog.vendors AS v
LEFT JOIN hotdog.ingredients AS i  ON v.vendor_id = i.vendor_id
ORDER BY v.vendor_name, i.ingredient_name;

-- See? Same result! LEFT JOIN with tables swapped = RIGHT JOIN.
-- Most SQL developers prefer LEFT JOIN because you always read
-- "keep everything from the FIRST table I mentioned."


-- ############################################################################
--
--                    PART 6: FULL OUTER JOIN — KEEP EVERYTHING FROM BOTH
--
-- ############################################################################
--
-- A FULL OUTER JOIN keeps EVERYTHING from BOTH tables. If a row
-- matches, great — you get the combined data. If a row on EITHER side
-- has no match, it still shows up, with NULL filling in the blanks.
--
-- Think of it as the "leave nobody behind" join.
--
-- VENN DIAGRAM:
--
--      ┌───────────┐   ┌───────────┐
--      │ ■■■■■■■■■ │   │ ■■■■■■■■■ │
--      │ ■■■■■■■┌┼───┼┐■■■■■■■■ │
--      │ ■■■■■■■│FULL│■■■■■■■■ │
--      │ ■■■■■■■│OUTR│■■■■■■■■ │
--      │ ■■■■■■■└┼───┼┘■■■■■■■■ │
--      └───────────┘   └───────────┘
--      ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
--      EVERYTHING from both tables
--
-- REAL-WORLD ANALOGY:
--   Imagine you're helping your boss compare two lists:
--     List 1: Ingredients we SHOULD have in stock
--     List 2: Ingredients that actually HAVE inventory records
--   You want to see the FULL picture:
--     ✓ Ingredients on both lists (everything is good)
--     ✗ Ingredients on List 1 but NOT List 2 (we forgot to set up inventory)
--     ✗ Inventory records on List 2 with no matching ingredient (data error?)
--   FULL OUTER JOIN gives you ALL THREE groups in one result.
--
-- SYNTAX:
--   SELECT columns
--   FROM table_a AS a
--   FULL OUTER JOIN table_b AS b  ON a.key = b.key;
-- ============================================================================


-- ============================================================================
-- SECTION 6.1: FULL OUTER JOIN — COMPLETE PICTURE OF INGREDIENTS & INVENTORY
-- ============================================================================
-- This shows us the full picture: ingredients without inventory AND
-- inventory records without matching ingredients (if any exist).
-- ============================================================================

SELECT
    i.ingredient_id,
    i.ingredient_name,
    inv.inventory_id,
    inv.quantity,
    inv.reorder_level
FROM hotdog.ingredients AS i
FULL OUTER JOIN hotdog.inventory AS inv  ON i.ingredient_id = inv.ingredient_id
ORDER BY i.ingredient_id;

-- Rows where ingredient_name is NULL → inventory record with no matching ingredient
-- Rows where quantity is NULL → ingredient with no inventory record
-- Rows where BOTH have values → properly matched data


-- ============================================================================
-- SECTION 6.2: FULL OUTER JOIN — VENDORS AND INGREDIENTS
-- ============================================================================
-- See the complete relationship between vendors and what they supply.
-- ============================================================================

SELECT
    v.vendor_name,
    i.ingredient_name,
    i.cost_per_unit
FROM hotdog.vendors AS v
FULL OUTER JOIN hotdog.ingredients AS i  ON v.vendor_id = i.vendor_id
ORDER BY v.vendor_name NULLS LAST, i.ingredient_name;

-- "NULLS LAST" puts the unmatched rows at the bottom so the output
-- is easier to read. You'll see:
--   - Vendors with their ingredients (matched)
--   - San Antonio Spice Co with NULL ingredients (vendor with no products)
--   - Any ingredients with NULL vendor (ingredient with no supplier)


-- ############################################################################
--
--                    PART 7: SEMI JOIN — "Does a Match Exist?"
--
-- ############################################################################
--
-- Sometimes you don't need to COMBINE data from two tables — you just
-- want to CHECK whether a match exists. That's a semi join.
--
-- A semi join says: "Give me rows from Table A, but ONLY if there is
-- at least one matching row in Table B."
--
-- HOW IS THIS DIFFERENT FROM INNER JOIN?
--   INNER JOIN → if Classic Dog was sold 50 times, you get 50 rows
--   SEMI JOIN  → Classic Dog appears exactly ONCE (yes, it has been sold)
--
-- PostgreSQL doesn't have a SEMI JOIN keyword. Instead, we write it
-- using WHERE EXISTS or WHERE ... IN.  Don't let those scare you —
-- the examples below walk through it step by step.
--
-- REAL-WORLD ANALOGY:
--   You're looking at the menu board and asking: "Which of these items
--   have EVER been ordered?" You don't care how many times — just
--   a simple yes-or-no for each item.
--
-- ============================================================================


-- ============================================================================
-- SECTION 7.1: THE PROBLEM — INNER JOIN CAN GIVE YOU DUPLICATES
-- ============================================================================
-- Let's see why INNER JOIN isn't always the right tool.
-- We want to know WHICH menu items have been sold.  That's it —
-- just the names, no duplicates.  Watch what happens with INNER JOIN:
-- ============================================================================

-- INNER JOIN gives us one row PER SALE of each item (many duplicates!)
SELECT
    mi.item_name,
    mi.price
FROM hotdog.menu_items AS mi
INNER JOIN hotdog.sale_items AS si  ON mi.menu_item_id = si.menu_item_id
ORDER BY mi.item_name;

-- Whoa! Classic Dog shows up over and over because it was sold many
-- times. But we just wanted to know IF it was sold, not every detail.
-- That's where a semi join helps.


-- ============================================================================
-- SECTION 7.2: SEMI JOIN USING EXISTS
-- ============================================================================
-- The EXISTS keyword checks: "Is there at least one row that matches?"
--   - If YES → include the menu item
--   - If NO  → skip it
--
-- Each menu item appears AT MOST ONCE in the results.
--
-- DON'T PANIC about the subquery inside the parentheses — just read
-- it in plain English (we'll translate it right after the query).
-- ============================================================================

SELECT
    mi.item_name,
    mi.price
FROM hotdog.menu_items AS mi
WHERE EXISTS (
    SELECT 1
    FROM hotdog.sale_items AS si
    WHERE si.menu_item_id = mi.menu_item_id
)
ORDER BY mi.item_name;

-- "mi" = menu_items (the table we're filtering)
-- "si" = sale_items (the table we're checking against)
--
-- HOW TO READ THIS IN PLAIN ENGLISH:
--   "Give me every menu item WHERE there EXISTS at least one
--    sale_item row with the same menu_item_id."
--
--   Or even simpler: "Show me menu items that have been sold."
--
-- Notice: Fiesta Dog (that we added earlier) does NOT appear because
-- it has never been sold. EXISTS found no matching rows for it.
--
-- ABOUT "SELECT 1":
--   The "SELECT 1" inside the parentheses is just a placeholder.
--   It could be SELECT *, SELECT 42, or SELECT 'taco'. EXISTS only
--   cares whether ANY rows come back — not what's in them.


-- ============================================================================
-- SECTION 7.3: SEMI JOIN USING IN (an easier-to-read alternative)
-- ============================================================================
-- If EXISTS feels confusing right now, you can use IN instead.
-- IN says: "Is this value in the following list?"
-- ============================================================================

SELECT
    mi.item_name,
    mi.price
FROM hotdog.menu_items AS mi
WHERE mi.menu_item_id IN (
    SELECT si.menu_item_id
    FROM hotdog.sale_items AS si
)
ORDER BY mi.item_name;

-- Same result! This says:
--   "Give me menu items whose menu_item_id appears IN the list of
--    menu_item_ids from sale_items."
--
-- WHICH SHOULD YOU USE?
--   IN     → easier to read, great for learning
--   EXISTS → can be faster on very large tables
--   Both give the same answer. Use whichever makes more sense to you.


-- ============================================================================
-- SECTION 7.4: SEMI JOIN — WHICH VENDORS HAVE SUPPLIED INGREDIENTS?
-- ============================================================================
-- Not all vendors necessarily have ingredients in our system.
-- Let's find only the vendors that DO supply at least one ingredient.
-- ============================================================================

SELECT
    v.vendor_name,
    v.contact_name,
    v.phone
FROM hotdog.vendors AS v
WHERE EXISTS (
    SELECT 1
    FROM hotdog.ingredients AS i
    WHERE i.vendor_id = v.vendor_id
)
ORDER BY v.vendor_name;

-- "v" = vendors, "i" = ingredients.
-- San Antonio Spice Co (the one we added with no ingredients) will
-- NOT appear because EXISTS found zero matching ingredients.


-- ############################################################################
--
--                    PART 8: ANTI JOIN — "Where is There NO Match?"
--
-- ############################################################################
--
-- An anti join is the OPPOSITE of a semi join.
-- It returns rows from Table A where there is NO matching row in Table B.
--
-- In other words: "Show me what's MISSING."
--
-- Just like semi joins, PostgreSQL doesn't have an ANTI JOIN keyword.
-- We use:  WHERE NOT EXISTS (...)  or  WHERE ... NOT IN (...)
--
-- REAL-WORLD ANALOGY:
--   You're looking at the menu board and asking: "Which items has
--   NOBODY ordered yet?"  These are the items collecting dust —
--   maybe you should run a special on them!
--
-- ============================================================================


-- ============================================================================
-- SECTION 8.1: ANTI JOIN USING NOT EXISTS
-- ============================================================================
-- Find menu items that have NEVER been sold.
-- This is the same pattern as EXISTS, just with NOT in front.
-- ============================================================================

SELECT
    mi.item_name,
    mi.price,
    mi.description
FROM hotdog.menu_items AS mi
WHERE NOT EXISTS (
    SELECT 1
    FROM hotdog.sale_items AS si
    WHERE si.menu_item_id = mi.menu_item_id
)
ORDER BY mi.item_name;

-- Fiesta Dog should appear here — it's on the menu but has zero sales.
-- In plain English: "Give me menu items where there are NO sale_item
-- rows with a matching menu_item_id."


-- ============================================================================
-- SECTION 8.2: ANTI JOIN USING NOT IN
-- ============================================================================
-- NOT IN is a simpler way to write it, but there's one gotcha to know.
-- ============================================================================

-- This works fine because menu_item_id in sale_items is NOT NULL:
SELECT
    mi.item_name,
    mi.price
FROM hotdog.menu_items AS mi
WHERE mi.menu_item_id NOT IN (
    SELECT si.menu_item_id
    FROM hotdog.sale_items AS si
)
ORDER BY mi.item_name;

-- ⚠️ HEADS UP FOR FUTURE REFERENCE:
-- NOT IN has a weird quirk: if the list it checks against contains
-- any NULL values, the whole thing breaks and returns NO rows.
-- You don't need to fully understand why right now — just remember:
--
--   SAFE CHOICE:   WHERE NOT EXISTS (...)   ← always works correctly
--   RISKY CHOICE:  WHERE ... NOT IN (...)   ← can break if NULLs sneak in
--
-- When in doubt, use NOT EXISTS. It's the safer option.


-- ============================================================================
-- SECTION 8.3: ANTI JOIN — VENDORS SUPPLYING NOTHING
-- ============================================================================
-- Find vendors who don't supply any ingredients in our system.
-- Maybe the contract ended, or we haven't added their products yet.
-- ============================================================================

SELECT
    v.vendor_name,
    v.contact_name,
    v.phone
FROM hotdog.vendors AS v
WHERE NOT EXISTS (
    SELECT 1
    FROM hotdog.ingredients AS i
    WHERE i.vendor_id = v.vendor_id
)
ORDER BY v.vendor_name;

-- "San Antonio Spice Co" should show up — they're in our vendors list
-- but we don't buy any ingredients from them. Useful for cleaning up
-- your data: "Why is this vendor here if we're not using them?"


-- ============================================================================
-- SECTION 8.4: BONUS — ANTI JOIN WITH LEFT JOIN + IS NULL
-- ============================================================================
-- You can also find "missing" data using LEFT JOIN + WHERE IS NULL.
-- This gives the same result as NOT EXISTS and is popular because
-- you already know how LEFT JOIN works!
-- ============================================================================

-- Menu items never sold (using LEFT JOIN pattern):
SELECT
    mi.item_name,
    mi.price,
    mi.description
FROM hotdog.menu_items AS mi
LEFT JOIN hotdog.sale_items AS si  ON mi.menu_item_id = si.menu_item_id
WHERE si.sale_item_id IS NULL
ORDER BY mi.item_name;

-- HOW IT WORKS (step by step):
--   1. LEFT JOIN keeps ALL menu items, even ones with no sales.
--   2. For unsold items, every sale_items column is NULL.
--   3. WHERE si.sale_item_id IS NULL keeps ONLY those unmatched rows.
--
-- This is the same result as NOT EXISTS — just a different way to
-- write it. Use whichever approach clicks best for you.


-- ############################################################################
--
--                    PART 9: JOINING MULTIPLE TABLES (3+ TABLE JOINS)
--
-- ############################################################################
--
-- In real life, answers often live across THREE or more tables.
-- Don't worry — you just add another JOIN line for each new table.
-- It's like following a chain of links:
--   sales → sale_items → menu_items
--   "Start with the sale, find what was in it, then look up the name."
--
-- SYNTAX:
--   SELECT ...
--   FROM table_a AS a
--   JOIN table_b AS b  ON a.key = b.key      ← first link
--   JOIN table_c AS c  ON b.key = c.key;     ← second link
--
-- Each new JOIN adds one more table to the chain.
-- ============================================================================


-- ============================================================================
-- SECTION 9.1: THREE-TABLE JOIN — SALES DETAIL REPORT
-- ============================================================================
-- Question: "For each sale, show who sold it, what was ordered, and
-- the item name — all in one result."
--
--   sales → tells us WHEN and by WHOM (owner_id)
--   sale_items → tells us WHAT was in the sale (menu_item_id, quantity)
--   menu_items → tells us the NAME and PRICE of each item
-- ============================================================================

SELECT
    s.sale_id,
    s.sale_date,
    o.first_name || ' ' || o.last_name AS owner_name,
    mi.item_name,
    si.quantity,
    si.line_total,
    s.payment_type
FROM hotdog.sales AS s
JOIN hotdog.owners     AS o   ON s.owner_id     = o.owner_id
JOIN hotdog.sale_items AS si  ON s.sale_id       = si.sale_id
JOIN hotdog.menu_items AS mi  ON si.menu_item_id = mi.menu_item_id
ORDER BY s.sale_id, si.sale_item_id;

-- Four tables joined! Here's how to read it:
--   s  = sales          (when did the sale happen?)
--   o  = owners         (who was working?)
--   si = sale_items     (what was on the receipt?)
--   mi = menu_items     (what's the name and price?)
--
-- Each JOIN follows one link in the chain. Take it one line at a time
-- and it's not as scary as it looks!


-- ============================================================================
-- SECTION 9.2: THREE-TABLE JOIN — RECIPE COST BREAKDOWN
-- ============================================================================
-- Question: "For each menu item, how much does each ingredient cost,
-- and who supplies it?"
--
--   menu_items → the item name
--   menu_item_ingredients (bridge table) → links item to ingredients
--   ingredients → the ingredient name, cost, and vendor
--   vendors → the vendor name
-- ============================================================================

SELECT
    mi.item_name,
    i.ingredient_name,
    mii.quantity_used,
    i.cost_per_unit,
    ROUND(mii.quantity_used * i.cost_per_unit, 2) AS ingredient_cost,
    v.vendor_name
FROM hotdog.menu_items AS mi
JOIN hotdog.menu_item_ingredients AS mii  ON mi.menu_item_id  = mii.menu_item_id
JOIN hotdog.ingredients           AS i    ON mii.ingredient_id = i.ingredient_id
JOIN hotdog.vendors               AS v    ON i.vendor_id       = v.vendor_id
ORDER BY mi.item_name, i.ingredient_name;

-- Four tables again, different chain:
--   mi  = menu_items              (what's on the menu)
--   mii = menu_item_ingredients   (the recipe — which ingredients go in)
--   i   = ingredients             (ingredient name and cost)
--   v   = vendors                 (who we buy from)
-- Don't worry about memorizing all the aliases — just pick short
-- names that remind you which table is which.


-- ============================================================================
-- SECTION 9.3: MULTI-TABLE JOIN WITH AGGREGATION
-- ============================================================================
-- Question: "How much revenue has each owner generated per menu item?"
-- This combines joins with GROUP BY for summary reporting.
-- ============================================================================

SELECT
    o.first_name || ' ' || o.last_name AS owner_name,
    mi.item_name,
    SUM(si.quantity)   AS total_qty_sold,
    SUM(si.line_total) AS total_revenue
FROM hotdog.sales AS s
JOIN hotdog.owners     AS o   ON s.owner_id      = o.owner_id
JOIN hotdog.sale_items AS si  ON s.sale_id        = si.sale_id
JOIN hotdog.menu_items AS mi  ON si.menu_item_id  = mi.menu_item_id
GROUP BY o.first_name, o.last_name, mi.item_name
ORDER BY owner_name, total_revenue DESC;

-- This is where SQL starts to feel really powerful — four tables
-- joined together, then grouped to make a business summary.
-- Take your time reading through the query. Each line does one job.


-- ############################################################################
--
--                    PART 10: KEY TAKEAWAYS & CHEAT SHEET
--
-- ############################################################################
--
-- ┌──────────────────┬──────────────────────────────────────────────────────┐
-- │   JOIN TYPE       │  WHAT IT RETURNS                                    │
-- ├──────────────────┼──────────────────────────────────────────────────────┤
-- │ INNER JOIN        │ Only rows that match in BOTH tables.                │
-- │                   │ No match = row is dropped.                          │
-- ├──────────────────┼──────────────────────────────────────────────────────┤
-- │ LEFT JOIN         │ ALL rows from the LEFT table +                      │
-- │                   │ matching rows from the right.                       │
-- │                   │ No match on right = NULLs.                          │
-- ├──────────────────┼──────────────────────────────────────────────────────┤
-- │ RIGHT JOIN        │ ALL rows from the RIGHT table +                     │
-- │                   │ matching rows from the left.                        │
-- │                   │ No match on left = NULLs.                           │
-- │                   │ (Same as LEFT JOIN with tables swapped.)            │
-- ├──────────────────┼──────────────────────────────────────────────────────┤
-- │ FULL OUTER JOIN   │ ALL rows from BOTH tables.                          │
-- │                   │ No match on either side = NULLs.                    │
-- ├──────────────────┼──────────────────────────────────────────────────────┤
-- │ SEMI JOIN         │ Rows from Table A where a match EXISTS in Table B.  │
-- │ (WHERE EXISTS)    │ Each row appears AT MOST ONCE. No columns from B.   │
-- ├──────────────────┼──────────────────────────────────────────────────────┤
-- │ ANTI JOIN         │ Rows from Table A where NO match exists in Table B. │
-- │ (WHERE NOT EXISTS)│ Finds "orphan" or "missing" data.                   │
-- └──────────────────┴──────────────────────────────────────────────────────┘
--
-- TABLE ALIASES CHEAT SHEET:
--   FROM hotdog.sales            AS s     ← "s" = sales
--   JOIN hotdog.owners           AS o     ← "o" = owners
--   JOIN hotdog.sale_items       AS si    ← "si" = sale_items
--   JOIN hotdog.menu_items       AS mi    ← "mi" = menu_items
--   JOIN hotdog.ingredients      AS i     ← "i" = ingredients
--   JOIN hotdog.vendors          AS v     ← "v" = vendors
--   JOIN hotdog.inventory        AS inv   ← "inv" = inventory
--   JOIN hotdog.menu_item_ingredients AS mii ← "mii" = menu_item_ingredients
--
-- TIPS FOR BEGINNERS:
--   1. Always give your tables short nicknames (aliases) when joining.
--   2. INNER JOIN is the default. Writing "JOIN" is the same as "INNER JOIN".
--   3. When in doubt, start with LEFT JOIN so you don't lose rows.
--      You can always switch to INNER JOIN later.
--   4. Prefer NOT EXISTS over NOT IN to avoid NULL surprises.
--   5. Multi-table joins are just single joins chained together.
--      Take them one JOIN at a time and they're totally manageable.
--   6. If your results look weird, check your ON clause first —
--      that's where most mistakes happen.
-- ============================================================================


-- ============================================================================
-- TRY IT YOURSELF — PRACTICE PROBLEMS
-- ============================================================================
-- These are meant to be tricky! Don't worry if you have to look back
-- at the examples above. That's how you learn.
-- ============================================================================

-- PROBLEM 1 (INNER JOIN — start here, it's the friendliest):
-- Write a query that shows each sale_item with the sale_date and
-- the item_name.
-- HINT: You'll need to join THREE tables: sales, sale_items, menu_items.
-- Use aliases: s for sales, si for sale_items, mi for menu_items.

-- PROBLEM 2 (LEFT JOIN):
-- Show ALL ingredients and their inventory quantity. Include ingredients
-- that have no inventory record (they should show NULL for quantity).
-- HINT: Start FROM ingredients, then LEFT JOIN inventory.

-- PROBLEM 3 (SEMI JOIN — use EXISTS):
-- Find all owners who have made at least one sale.
-- HINT: WHERE EXISTS ( SELECT 1 FROM hotdog.sales AS s WHERE ... )

-- PROBLEM 4 (ANTI JOIN — use NOT EXISTS):
-- Find all ingredients that are NOT used in ANY menu item recipe.
-- HINT: Check the menu_item_ingredients table with NOT EXISTS.

-- PROBLEM 5 (MULTI-TABLE — the big challenge!):
-- Build a "receipt" for sale_id = 1. Show the sale_date, owner name,
-- each item_name ordered, the quantity, and the line_total.
-- HINT: Join sales → owners, sales → sale_items → menu_items,
--       then add WHERE s.sale_id = 1.

-- ============================================================================
-- END OF LESSON
-- ============================================================================
