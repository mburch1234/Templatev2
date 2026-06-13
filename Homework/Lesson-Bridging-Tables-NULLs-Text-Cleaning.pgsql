-- ============================================================================
-- LESSON: Bridging Tables, NULL Handling, and Text Cleaning in PostgreSQL
-- ============================================================================
-- Building on the Hotdog Stand database, this lesson covers three essential
-- SQL skills you'll use in real business data work:
--
--   PART 1:  Bridging Tables (Many-to-Many Relationships)
--   PART 2:  Handling NULL / Missing Values
--   PART 3:  Basic Text Manipulation & Data Cleaning
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
--                    PART 1: BRIDGING TABLES
--
-- ############################################################################
--
-- WHAT IS A BRIDGING TABLE?
-- -------------------------
-- A bridging table (also called a "junction table") connects two tables
-- that have a MANY-TO-MANY relationship.
--
-- REAL-WORLD ANALOGY:
--   Think about students and classes at UTSA.
--   - One STUDENT takes MANY classes.
--   - One CLASS has MANY students.
--   You can't put all the class IDs into one column of the student table,
--   and you can't put all the student IDs into one column of the class table.
--   So the registrar uses an ENROLLMENT table in the middle — each row
--   says "this student is enrolled in this class."
--
-- IN OUR HOTDOG STAND:
--   - One MENU ITEM uses MANY ingredients  (Chili Dog needs beef, bun, chili, cheese)
--   - One INGREDIENT is in MANY menu items (Beef Frank is in Classic Dog, Chili Dog, etc.)
--   - The bridging table: menu_item_ingredients  (one row per combination)
--
-- Here's a picture:
--
-- ┌──────────────┐       ┌───────────────────────┐       ┌──────────────┐
-- │  menu_items   │       │ menu_item_ingredients  │       │ ingredients  │
-- │──────────────│       │ (BRIDGING TABLE)       │       │──────────────│
-- │ menu_item_id ◄───────│ menu_item_id           │       │ingredient_id │
-- │ item_name    │       │ ingredient_id          ├──────►│ingredient_name│
-- │ price        │       │ quantity_used          │       │ cost_per_unit│
-- └──────────────┘       └───────────────────────┘       └──────────────┘
--
-- ============================================================================


-- ============================================================================
-- SECTION 1.1: LOOK AT THE BRIDGING TABLE
-- ============================================================================
-- Let's first look at the raw bridging table.
-- By itself it's just numbers — not very useful to read.
-- ============================================================================

SELECT *
FROM hotdog.menu_item_ingredients
ORDER BY menu_item_id, ingredient_id;

-- You should see rows like:
--   menu_item_id=1, ingredient_id=1, quantity_used=1.00
-- That means menu item #1 uses ingredient #1, quantity 1.
-- But what IS menu item #1? What IS ingredient #1? We need JOINs!


-- ============================================================================
-- SECTION 1.2: JOIN THROUGH THE BRIDGE TO SEE NAMES
-- ============================================================================
-- To make the bridging table useful, we JOIN it to BOTH parent tables.
-- This turns those ID numbers into readable names.
--
-- Think of it like this:
--   1. Start at the bridging table (the middle)
--   2. JOIN to menu_items to get the item NAME
--   3. JOIN to ingredients to get the ingredient NAME
--
-- IMPORTANT NOTE ABOUT TABLE NICKNAMES:
--   When you JOIN multiple tables, some columns exist in more than one
--   table (like menu_item_id).  SQL wouldn't know which table you mean!
--   So we give each table a short NICKNAME (called a "table alias"):
--
--     hotdog.menu_item_ingredients AS bridge
--     hotdog.menu_items            AS items
--     hotdog.ingredients           AS ingredients
--
--   Then we write  items.item_name  instead of  hotdog.menu_items.item_name.
--   The nickname just saves typing — it doesn't change anything.
-- ============================================================================

SELECT
    items.item_name,
    ingredients.ingredient_name,
    bridge.quantity_used,
    ingredients.unit
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items            AS items       ON bridge.menu_item_id  = items.menu_item_id
JOIN hotdog.ingredients           AS ingredients ON bridge.ingredient_id = ingredients.ingredient_id
ORDER BY items.item_name, ingredients.ingredient_name;

-- NOW you can see:  "Classic Dog" uses "Beef Frank", "Ketchup", etc.
-- That's the power of a bridging table + JOINs!


-- ============================================================================
-- SECTION 1.3: COMMON QUESTIONS YOU CAN ANSWER
-- ============================================================================

-- -------------------------------------------------
-- QUESTION 1: "What ingredients are in the Chili Cheese Dog?"
-- We filter by the menu item name using WHERE.
-- -------------------------------------------------
SELECT
    ingredients.ingredient_name,
    bridge.quantity_used,
    ingredients.unit
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items            AS items       ON bridge.menu_item_id  = items.menu_item_id
JOIN hotdog.ingredients           AS ingredients ON bridge.ingredient_id = ingredients.ingredient_id
WHERE items.item_name = 'Chili Cheese Dog';


-- -------------------------------------------------
-- QUESTION 2: "Which menu items use Beef Frank?"
-- Same three tables, but now we filter by the ingredient name instead.
-- -------------------------------------------------
SELECT
    items.item_name,
    items.price
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items            AS items       ON bridge.menu_item_id  = items.menu_item_id
JOIN hotdog.ingredients           AS ingredients ON bridge.ingredient_id = ingredients.ingredient_id
WHERE ingredients.ingredient_name = 'Beef Frank'
ORDER BY items.item_name;


-- -------------------------------------------------
-- QUESTION 3: "How many ingredients does each menu item use?"
-- COUNT how many rows each item has in the bridging table.
-- -------------------------------------------------
SELECT
    items.item_name,
    COUNT(*) AS number_of_ingredients
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.menu_items            AS items ON bridge.menu_item_id = items.menu_item_id
GROUP BY items.item_name
ORDER BY number_of_ingredients DESC;


-- -------------------------------------------------
-- QUESTION 4: "How many menu items does each ingredient appear in?"
-- Same idea, but grouped by ingredient instead.
-- -------------------------------------------------
SELECT
    ingredients.ingredient_name,
    COUNT(*) AS used_in_how_many_items
FROM hotdog.menu_item_ingredients AS bridge
JOIN hotdog.ingredients           AS ingredients ON bridge.ingredient_id = ingredients.ingredient_id
GROUP BY ingredients.ingredient_name
ORDER BY used_in_how_many_items DESC;


-- ============================================================================
-- SECTION 1.4: BUILD YOUR OWN BRIDGING TABLE — OWNER FAVORITES
-- ============================================================================
-- Let's create a NEW many-to-many relationship.
-- We want to track which owners LIKE which menu items (like a favorites list).
--
--   - One owner can favorite MANY items
--   - One item can be favorited by MANY owners
--   - We need a bridging table in the middle!
-- ============================================================================

-- Step 1: Create the bridging table
DROP TABLE IF EXISTS hotdog.owner_favorites;

CREATE TABLE hotdog.owner_favorites (
    owner_favorite_id  SERIAL PRIMARY KEY,
    owner_id           INT NOT NULL REFERENCES hotdog.owners(owner_id),
    menu_item_id       INT NOT NULL REFERENCES hotdog.menu_items(menu_item_id),
    added_date         DATE DEFAULT CURRENT_DATE
);

-- Step 2: Insert some data (each row = "this owner likes this item")
INSERT INTO hotdog.owner_favorites (owner_id, menu_item_id) VALUES
    (1, 1),   -- Tony likes Classic Dog
    (1, 2),   -- Tony likes Chili Cheese Dog
    (1, 7),   -- Tony likes The Works Dog
    (2, 3),   -- Maria likes Turkey Dog
    (2, 4),   -- Maria likes Veggie Dog
    (3, 2),   -- James likes Chili Cheese Dog
    (3, 6),   -- James likes Spicy Jalapeno Dog
    (3, 5);   -- James likes Sauerkraut Dog

-- Step 3: Query through the bridge to see names (not just IDs)
SELECT
    owners.first_name,
    owners.last_name,
    items.item_name,
    items.price
FROM hotdog.owner_favorites AS favorites
JOIN hotdog.owners          AS owners ON favorites.owner_id    = owners.owner_id
JOIN hotdog.menu_items      AS items  ON favorites.menu_item_id = items.menu_item_id
ORDER BY owners.first_name, items.item_name;

-- Step 4: Which items are favorited by MORE THAN ONE owner?
SELECT
    items.item_name,
    COUNT(*) AS favorited_by_count
FROM hotdog.owner_favorites AS favorites
JOIN hotdog.menu_items      AS items ON favorites.menu_item_id = items.menu_item_id
GROUP BY items.item_name
HAVING COUNT(*) > 1;

-- TRY IT YOURSELF:
-- Write a query to find which owners favorited "Chili Cheese Dog"
-- (Hint: add a WHERE clause filtering on items.item_name)


-- ============================================================================
-- SECTION 1.5: KEY TAKEAWAYS — BRIDGING TABLES
-- ============================================================================
-- 1. When two tables have a MANY-TO-MANY relationship, you need a
--    THIRD table (the bridge) to connect them.
-- 2. The bridge table has at least TWO foreign key columns — one pointing
--    to each parent table.
-- 3. Each ROW in the bridge = one link  ("this item uses this ingredient")
-- 4. You can add extra info columns (like quantity_used or added_date).
-- 5. To read the bridge, JOIN it to BOTH parent tables.
-- ============================================================================


-- ############################################################################
--
--                    PART 2: HANDLING NULL VALUES
--
-- ############################################################################
--
-- WHAT IS NULL?
-- -------------
-- NULL means "missing" or "unknown."  It is NOT zero. It is NOT blank.
-- It is the complete absence of a value.
--
-- REAL-WORLD EXAMPLES:
--   - A customer left the phone number field blank on a form  → NULL
--   - A product hasn't been restocked yet (no date to record) → NULL
--   - A reviewer gave no star rating                          → NULL
--
-- WHY DOES IT MATTER?
--   NULL behaves differently than regular values in SQL.
--   If you don't handle it, your queries will give wrong results.
--
-- ============================================================================


-- ============================================================================
-- SECTION 2.1: SET UP MESSY PRACTICE DATA
-- ============================================================================
-- We'll create a customer_reviews table with intentionally messy data.
-- This simulates what real-world data looks like when customers fill out
-- an online review form — some fields are blank, names are typed in
-- different ways, phone formats vary, etc.
-- ============================================================================

DROP TABLE IF EXISTS hotdog.customer_reviews CASCADE;

CREATE TABLE hotdog.customer_reviews (
    review_id      SERIAL PRIMARY KEY,
    customer_name  VARCHAR(100),
    email          VARCHAR(100),
    phone          VARCHAR(30),
    menu_item_id   INT REFERENCES hotdog.menu_items(menu_item_id),
    rating         INT,           -- 1 to 5 stars
    review_text    TEXT,
    review_date    DATE
);

-- Insert 12 messy reviews (look at the problems in the comments!)
INSERT INTO hotdog.customer_reviews
    (customer_name, email, phone, menu_item_id, rating, review_text, review_date)
VALUES
    ('John Smith',       'john@email.com',    '210-555-1111',   1, 5, 'Best classic dog in SA!',                '2026-03-20'),
    ('jane doe',         'JANE@EMAIL.COM',    '(210) 555-2222', 2, 4, 'Chili was great but a bit messy',       '2026-03-20'),  -- name all lowercase, email all CAPS
    ('BOB JOHNSON',      NULL,                '210.555.3333',   1, NULL, NULL,                                   '2026-03-21'),  -- no email, no rating, no review
    ('  Maria Garcia  ', 'maria@email.com',   NULL,             4, 5, '  Love the veggie dog!   ',             '2026-03-21'),  -- extra spaces in name and review
    ('Carlos Ruiz',      'carlos@email.com',  '210-555-5555',   NULL, 3, 'Good but nothing special',           NULL),           -- no menu item, no date
    (NULL,               'mystery@email.com', '210-555-6666',   2, 5, 'AMAZING chili cheese dog!!!',           '2026-03-22'),  -- no name at all!
    ('lisa WONG',        'Lisa@Email.Com',    '210 555 7777',   5, NULL, '',                                    '2026-03-22'),  -- empty string (not NULL) for review
    ('Tony Martinez',    'tony@email.com',    '2105558888',     7, 4, 'the works dog is aptly named. so good.','2026-03-23'),  -- phone has no dashes
    ('  ANA LOPEZ',      'ANA@email.COM',     NULL,             3, 2, 'turkey dog was   kind of   dry',        '2026-03-23'),  -- leading spaces, extra spaces in review
    ('David Kim',        NULL,                NULL,             6, 5, 'Spicy jalapeno dog 10/10',              '2026-03-23'),  -- no email, no phone
    ('sarah  connor',    'sarah@email.com',   '210-555-0000',   NULL, NULL, NULL,                               NULL),          -- double space in name, lots of NULLs
    ('Pat OBrien',       'pat@email.com',     '210-555-1212',   1, 4, 'Classic and reliable. Cant go wrong.',  '2026-03-24');

-- Look at all the messy data:
SELECT * FROM hotdog.customer_reviews ORDER BY review_id;


-- ============================================================================
-- SECTION 2.2: FINDING NULLs — IS NULL / IS NOT NULL
-- ============================================================================
-- The #1 rule of NULLs in SQL:
--
--   WRONG:   WHERE email = NULL      ← This NEVER works!
--   RIGHT:   WHERE email IS NULL     ← This is how you check for NULL
--
-- Why? Because NULL means "unknown," and you can't check if something
-- equals "unknown" — that doesn't make sense logically.
-- ============================================================================

-- Find all reviews where the customer didn't give their email:
SELECT review_id, customer_name, email
FROM hotdog.customer_reviews
WHERE email IS NULL;

-- Find all reviews that DO have a rating:
SELECT review_id, customer_name, rating
FROM hotdog.customer_reviews
WHERE rating IS NOT NULL;

-- TRY IT YOURSELF:
-- Write a query to find all reviews where the phone number is missing.


-- ============================================================================
-- SECTION 2.3: COUNTING NULLs IN EACH COLUMN
-- ============================================================================
-- This is a handy trick for checking data quality.
--
-- HOW IT WORKS:
--   COUNT(*)        = counts ALL rows (including NULLs)
--   COUNT(column)   = counts only rows where that column is NOT NULL
--   The difference  = how many NULLs are in that column
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
-- SECTION 2.4: REPLACING NULLs — COALESCE()
-- ============================================================================
-- COALESCE() is your go-to tool for replacing NULL with a default value.
--
-- HOW IT WORKS:
--   COALESCE(value, default)
--     - If value is NOT NULL → returns value (keeps the original)
--     - If value IS NULL     → returns default (your replacement)
--
-- EXAMPLE:
--   COALESCE(phone, 'N/A')
--     phone = '210-555-1111'  →  returns '210-555-1111'
--     phone = NULL            →  returns 'N/A'
-- ============================================================================

-- Replace NULLs with friendly text for a report:
SELECT
    review_id,
    COALESCE(customer_name, 'Anonymous'),
    COALESCE(email, 'no email provided'),
    COALESCE(phone, 'no phone provided'),
    COALESCE(rating, 0),
    COALESCE(review_text, 'no review written')
FROM hotdog.customer_reviews
ORDER BY review_id;


-- ============================================================================
-- SECTION 2.5: TURNING EMPTY STRINGS INTO NULLs — NULLIF()
-- ============================================================================
-- Sometimes your data has EMPTY STRINGS ('') instead of NULL.
-- An empty string LOOKS blank but SQL treats it differently than NULL.
--
-- NULLIF(a, b) → returns NULL if a equals b, otherwise returns a.
--
-- EXAMPLE:
--   NULLIF('', '') → NULL      (empty string becomes NULL)
--   NULLIF('Hello', '') → 'Hello'  (keeps the value)
--
-- Look at review_id 7 — lisa WONG has an empty string '' for review_text:
-- ============================================================================

-- See the difference between NULL and empty string:
SELECT review_id, review_text, review_text IS NULL AS is_it_null
FROM hotdog.customer_reviews
WHERE review_id IN (3, 7);
-- review_id 3 (Bob) has NULL → is_it_null = TRUE
-- review_id 7 (Lisa) has ''  → is_it_null = FALSE  (it's blank, but not NULL!)

-- Use NULLIF to convert '' to NULL, then COALESCE to give a default:
SELECT
    review_id,
    review_text,
    NULLIF(review_text, ''),
    COALESCE(NULLIF(review_text, ''), 'no review written')
FROM hotdog.customer_reviews
ORDER BY review_id;


-- ============================================================================
-- SECTION 2.6: NULLs IN MATH — NULL IS "CONTAGIOUS"
-- ============================================================================
-- Any math with NULL gives NULL:
--   5 + NULL  = NULL   (not 5!)
--   NULL * 2  = NULL   (not 0!)
--
-- Think of it like this: if you don't know someone's rating,
-- you can't double it — the answer is still "unknown."
--
-- Use COALESCE to replace NULL with 0 (or another number) before doing math.
-- ============================================================================

-- See the problem — NULL ratings give NULL when we try to double them:
SELECT
    review_id,
    customer_name,
    rating,
    rating * 2                  -- NULL * 2 = NULL !
FROM hotdog.customer_reviews
ORDER BY review_id;

-- Fix it with COALESCE — treat missing ratings as 0:
SELECT
    review_id,
    customer_name,
    rating,
    COALESCE(rating, 0) * 2    -- now NULL becomes 0, then 0*2 = 0
FROM hotdog.customer_reviews
ORDER BY review_id;


-- ============================================================================
-- SECTION 2.7: NULLs IN AVERAGES
-- ============================================================================
-- AVG() automatically IGNORES NULLs.  This can be good or bad depending
-- on what you want:
--
--   AVG(rating) with values [5, 4, NULL, 5, 3]
--     → averages only 5, 4, 5, 3 → result = 4.25  (ignores the NULL)
--
--   AVG(COALESCE(rating, 0)) with same values
--     → averages 5, 4, 0, 5, 3 → result = 3.40  (treats NULL as zero)
-- ============================================================================

SELECT
    ROUND(AVG(rating), 2),
    ROUND(AVG(COALESCE(rating, 0)), 2),
    COUNT(rating),
    COUNT(*)
FROM hotdog.customer_reviews;


-- ============================================================================
-- SECTION 2.8: NULLs AND JOINs — INNER JOIN vs LEFT JOIN
-- ============================================================================
-- Some reviews have menu_item_id = NULL (the customer didn't say what
-- they ordered).
--
-- INNER JOIN:  Only shows rows where BOTH sides have a match.
--              Reviews with NULL menu_item_id get DROPPED (lost!).
--
-- LEFT JOIN:   Keeps ALL rows from the left table (customer_reviews),
--              and fills in NULLs on the right side when there's no match.
--
-- NOTE: We need table nicknames here because both tables have columns
--       with the same name (like menu_item_id). We use "reviews" and
--       "items" so SQL knows which table we mean.
-- ============================================================================

-- INNER JOIN — notice some reviews DISAPPEAR! (Carlos and Sarah have no menu item)
SELECT
    reviews.review_id,
    reviews.customer_name,
    items.item_name,
    reviews.rating
FROM hotdog.customer_reviews AS reviews
JOIN hotdog.menu_items       AS items ON reviews.menu_item_id = items.menu_item_id
ORDER BY reviews.review_id;

-- LEFT JOIN — ALL reviews show up, unmatched ones show NULL for item_name
SELECT
    reviews.review_id,
    reviews.customer_name,
    items.item_name,
    reviews.rating
FROM hotdog.customer_reviews AS reviews
LEFT JOIN hotdog.menu_items  AS items ON reviews.menu_item_id = items.menu_item_id
ORDER BY reviews.review_id;

-- Combine LEFT JOIN + COALESCE for a clean report:
SELECT
    reviews.review_id,
    COALESCE(reviews.customer_name, 'Anonymous'),
    COALESCE(items.item_name, 'Item Not Specified'),
    COALESCE(reviews.rating, 0)
FROM hotdog.customer_reviews AS reviews
LEFT JOIN hotdog.menu_items  AS items ON reviews.menu_item_id = items.menu_item_id
ORDER BY reviews.review_id;


-- ############################################################################
--
--                    PART 3: TEXT MANIPULATION & DATA CLEANING
--
-- ############################################################################
--
-- WHY DO WE NEED THIS?
-- --------------------
-- Real-world text data is MESSY.  People type things differently:
--   - Names:    'jane doe',  'BOB JOHNSON',  '  Maria Garcia  '
--   - Emails:   'JANE@EMAIL.COM',  'Lisa@Email.Com'
--   - Phones:   '210-555-1111',  '(210) 555-2222',  '210.555.3333'
--
-- Before you can analyze data, you need to STANDARDIZE it.
-- PostgreSQL has built-in functions to fix all of these issues.
--
-- ============================================================================


-- ============================================================================
-- SECTION 3.1: CHANGING CASE — UPPER(), LOWER(), INITCAP()
-- ============================================================================
--
--   UPPER('hello')         → 'HELLO'          (all capitals)
--   LOWER('HELLO')         → 'hello'          (all lowercase)
--   INITCAP('hello world') → 'Hello World'    (first letter of each word capitalized)
--
-- INITCAP is usually the best choice for names.
-- LOWER is usually the best choice for email addresses.
-- ============================================================================

-- See how each function transforms the messy customer names:
SELECT
    customer_name,
    UPPER(customer_name),
    LOWER(customer_name),
    INITCAP(customer_name)
FROM hotdog.customer_reviews
WHERE customer_name IS NOT NULL
ORDER BY review_id;

-- Notice how INITCAP fixes everything:
--   'jane doe'     → 'Jane Doe'
--   'BOB JOHNSON'  → 'Bob Johnson'
--   'lisa WONG'    → 'Lisa Wong'

-- Standardize emails to lowercase:
SELECT
    email,
    LOWER(email)
FROM hotdog.customer_reviews
WHERE email IS NOT NULL
ORDER BY review_id;


-- ============================================================================
-- SECTION 3.2: REMOVING EXTRA SPACES — TRIM()
-- ============================================================================
--
--   TRIM('  hello  ')  → 'hello'     (removes spaces from both sides)
--   LTRIM('  hello')   → 'hello'     (removes spaces from the left only)
--   RTRIM('hello  ')   → 'hello'     (removes spaces from the right only)
--
-- Look at our data:
--   '  Maria Garcia  '  has spaces on BOTH sides
--   '  ANA LOPEZ'       has spaces on the LEFT
-- ============================================================================

-- Use the > < markers to SEE the extra spaces:
SELECT
    review_id,
    '>' || customer_name || '<',         -- see the spaces
    '>' || TRIM(customer_name) || '<'    -- spaces removed!
FROM hotdog.customer_reviews
WHERE customer_name LIKE ' %'     -- starts with a space
   OR customer_name LIKE '% '     -- ends with a space
ORDER BY review_id;


-- ============================================================================
-- SECTION 3.3: COMBINING TRIM + INITCAP
-- ============================================================================
-- When cleaning names, always TRIM first, then fix the case.
-- You can nest functions: the inner one runs first.
--
--   INITCAP(TRIM('  ANA LOPEZ'))
--     Step 1: TRIM removes spaces  → 'ANA LOPEZ'
--     Step 2: INITCAP fixes case   → 'Ana Lopez'
-- ============================================================================

SELECT
    review_id,
    customer_name,
    INITCAP(TRIM(customer_name))
FROM hotdog.customer_reviews
WHERE customer_name IS NOT NULL
ORDER BY review_id;

-- TRY IT YOURSELF:
-- Write a query that shows email in lowercase AND trimmed.
-- Hint: LOWER(TRIM(email))


-- ============================================================================
-- SECTION 3.4: MEASURING AND EXTRACTING TEXT — LENGTH(), LEFT(), RIGHT()
-- ============================================================================
--
--   LENGTH('Hello')          → 5          (counts characters)
--   LEFT('Hello', 3)         → 'Hel'     (first 3 characters)
--   RIGHT('Hello', 2)        → 'lo'      (last 2 characters)
-- ============================================================================

SELECT
    customer_name,
    LENGTH(customer_name),
    LEFT(customer_name, 1)
FROM hotdog.customer_reviews
WHERE customer_name IS NOT NULL
ORDER BY review_id;


-- ============================================================================
-- SECTION 3.5: FINDING TEXT INSIDE TEXT — POSITION()
-- ============================================================================
--
--   POSITION('find_this' IN some_column)
--     → returns the position number where it was found
--     → returns 0 if not found
--
--   POSITION('@' IN 'john@email.com')  → 5  (the @ is at position 5)
-- ============================================================================

-- Find where the '@' symbol is in each email:
SELECT
    email,
    POSITION('@' IN email)
FROM hotdog.customer_reviews
WHERE email IS NOT NULL
ORDER BY review_id;


-- ============================================================================
-- SECTION 3.6: REPLACING TEXT — REPLACE()
-- ============================================================================
--
--   REPLACE(string, 'old_text', 'new_text')
--     → finds ALL occurrences of old_text and swaps them for new_text
--
--   REPLACE('210.555.3333', '.', '-')  → '210-555-3333'
-- ============================================================================

-- Simple phone cleaning: replace dots with dashes
SELECT
    phone,
    REPLACE(phone, '.', '-')
FROM hotdog.customer_reviews
WHERE phone LIKE '%.%';

-- You can chain REPLACE to fix multiple issues step by step:
-- (Read from the inside out — innermost REPLACE runs first)
SELECT
    phone,
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(phone, '(', ''),   -- Step 1: remove (
            ')', ''),                      -- Step 2: remove )
        '.', '-'),                         -- Step 3: dots → dashes
    ' ', '')                               -- Step 4: remove spaces
FROM hotdog.customer_reviews
WHERE phone IS NOT NULL
ORDER BY review_id;


-- ============================================================================
-- SECTION 3.7: PATTERN-BASED REPLACE — REGEXP_REPLACE()  (OPTIONAL / BONUS)
-- ============================================================================
-- REGEXP_REPLACE is like REPLACE but uses PATTERNS instead of exact text.
-- Don't worry if this feels advanced — it's a bonus tool. You only need
-- to know two simple patterns for this class:
--
-- PATTERN 1:  '[^0-9]'   means "anything that is NOT a digit (0-9)"
--             Great for stripping phone numbers down to just numbers.
--
-- PATTERN 2:  '\s+'      means "one or more spaces in a row"
--             Great for collapsing double/triple spaces into one space.
--
-- The 'g' at the end means "do it everywhere" (not just the first match).
-- ============================================================================

-- Strip phone numbers down to just digits:
--   '(210) 555-2222'  →  '2105552222'
--   '210.555.3333'    →  '2105553333'
SELECT
    phone,
    REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
FROM hotdog.customer_reviews
WHERE phone IS NOT NULL
ORDER BY review_id;

-- Collapse double spaces into a single space:
--   'sarah  connor'                   →  'sarah connor'
--   'turkey dog was   kind of   dry'  →  'turkey dog was kind of dry'
SELECT
    customer_name,
    REGEXP_REPLACE(customer_name, '\s+', ' ', 'g')
FROM hotdog.customer_reviews
WHERE customer_name LIKE '%  %'   -- find names with double spaces
ORDER BY review_id;


-- ============================================================================
-- SECTION 3.8: COMBINING TEXT WITH ||  (CONCATENATION)
-- ============================================================================
--   ||  joins pieces of text together (called "concatenation")
--
--   'Hello' || ' ' || 'World'  → 'Hello World'
--
-- WARNING:  If ANY part is NULL, the whole result is NULL!
--   'Hello' || NULL  → NULL  (not 'Hello')
--
-- Use COALESCE to protect against this.
-- ============================================================================

-- Create a full greeting — but watch out for the NULL name (review_id 6):
SELECT
    review_id,
    'Review by: ' || customer_name,                           -- NULL if name is NULL!
    'Review by: ' || COALESCE(customer_name, 'Anonymous')     -- safe version
FROM hotdog.customer_reviews
ORDER BY review_id;


-- ============================================================================
-- SECTION 3.9: PUTTING IT ALL TOGETHER — CLEAN THE WHOLE TABLE
-- ============================================================================
-- Now let's apply everything we learned in ONE query to clean all columns.
--
-- What we're doing to each column:
--   customer_name → trim spaces, fix double spaces, proper case, default for NULL
--   email         → lowercase for consistency, default for NULL
--   phone         → show NULL as 'N/A', otherwise strip to digits and reformat
--   item_name     → use LEFT JOIN to look up the name, default for NULL
--   rating        → replace NULL with 0
--   review_text   → trim, fix spaces, handle empty strings and NULLs
--   review_date   → replace NULL with today's date
--
-- NOTE: We need table nicknames here because we are JOINing two tables.
--       "reviews" = customer_reviews,  "items" = menu_items
-- ============================================================================

SELECT
    reviews.review_id,

    -- Clean the name: trim → fix double spaces → proper case → handle NULL
    COALESCE(
        INITCAP(TRIM(REGEXP_REPLACE(customer_name, '\s+', ' ', 'g'))),
        'Anonymous'
    ),

    -- Clean the email: lowercase everything, or show 'no email'
    COALESCE(LOWER(email), 'no email'),

    -- Clean the phone: if NULL show N/A, otherwise reformat
    CASE
        WHEN phone IS NULL THEN 'N/A'
        ELSE
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 1 FOR 3)
            || '-' ||
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 4 FOR 3)
            || '-' ||
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 7 FOR 4)
    END,

    -- Get the menu item name using LEFT JOIN (keeps rows with NULL menu_item_id)
    COALESCE(items.item_name, 'Not Specified'),

    -- Replace missing ratings with 0
    COALESCE(reviews.rating, 0),

    -- Clean review: handle NULL, empty string, and extra spaces
    COALESCE(
        NULLIF(TRIM(REGEXP_REPLACE(COALESCE(reviews.review_text, ''), '\s+', ' ', 'g')), ''),
        'No review provided'
    ),

    -- Replace missing dates with today
    COALESCE(reviews.review_date, CURRENT_DATE)

FROM hotdog.customer_reviews AS reviews
LEFT JOIN hotdog.menu_items  AS items ON reviews.menu_item_id = items.menu_item_id
ORDER BY reviews.review_id;


-- ============================================================================
-- SECTION 3.10: SAVE THE CLEANED DATA INTO A NEW TABLE
-- ============================================================================
-- Best practice: create a NEW table with the clean data.
-- This way you still have the original messy data if you need it.
--
-- CREATE TABLE ... AS SELECT ...
--   creates a brand new table and fills it with the results of your query.
-- ============================================================================

DROP TABLE IF EXISTS hotdog.customer_reviews_clean;

CREATE TABLE hotdog.customer_reviews_clean AS
SELECT
    review_id,
    COALESCE(
        INITCAP(TRIM(REGEXP_REPLACE(customer_name, '\s+', ' ', 'g'))),
        'Anonymous'
    ) AS customer_name,
    COALESCE(LOWER(email), 'no email') AS email,
    CASE
        WHEN phone IS NULL THEN NULL
        ELSE
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 1 FOR 3)
            || '-' ||
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 4 FOR 3)
            || '-' ||
            SUBSTRING(REGEXP_REPLACE(phone, '[^0-9]', '', 'g') FROM 7 FOR 4)
    END AS phone,
    menu_item_id,
    COALESCE(rating, 0) AS rating,
    NULLIF(TRIM(REGEXP_REPLACE(COALESCE(review_text, ''), '\s+', ' ', 'g')), '') AS review_text,
    COALESCE(review_date, CURRENT_DATE) AS review_date
FROM hotdog.customer_reviews;

-- Check the clean version:
SELECT * FROM hotdog.customer_reviews_clean ORDER BY review_id;

-- Compare side by side — original vs clean:
SELECT 'ORIGINAL', customer_name, email, phone
FROM hotdog.customer_reviews ORDER BY review_id;

SELECT 'CLEANED', customer_name, email, phone
FROM hotdog.customer_reviews_clean ORDER BY review_id;


-- ============================================================================
-- QUICK REFERENCE CHEAT SHEET
-- ============================================================================
--
--  NULL FUNCTIONS:
--    IS NULL / IS NOT NULL    Check if a value is missing
--    COALESCE(val, default)   Replace NULL with a default value
--    NULLIF(val, '')          Turn a specific value (like '') into NULL
--    COUNT(*)                 Counts all rows (including NULLs)
--    COUNT(column)            Counts only non-NULL rows
--
--  TEXT CASE:
--    UPPER(text)              → 'HELLO WORLD'
--    LOWER(text)              → 'hello world'
--    INITCAP(text)            → 'Hello World'
--
--  TEXT CLEANUP:
--    TRIM(text)               Remove leading/trailing spaces
--    LENGTH(text)             Count characters
--    LEFT(text, n)            First n characters
--    RIGHT(text, n)           Last n characters
--    POSITION('x' IN text)    Find where 'x' appears
--    REPLACE(text, old, new)  Replace exact text
--    REGEXP_REPLACE(text, pattern, new, 'g')
--                             Replace by pattern (bonus/advanced)
--
--  TWO PATTERNS YOU SHOULD KNOW:
--    '[^0-9]'                 Anything that is NOT a digit
--    '\s+'                    One or more spaces in a row
--
--  CONCATENATION (joining text together):
--    'A' || 'B'               → 'AB'  (but NULL if either side is NULL!)
--
-- ============================================================================


-- ============================================================================
-- LESSON COMPLETE!
-- ============================================================================
-- You now know how to:
--   1. Understand WHY bridging tables exist (many-to-many relationships)
--   2. Query THROUGH a bridging table with JOINs
--   3. CREATE your own bridging table
--   4. Find and handle NULL values with IS NULL, COALESCE, NULLIF
--   5. Understand how NULLs affect math, averages, and JOINs
--   6. Clean text with UPPER, LOWER, INITCAP, TRIM
--   7. Standardize messy data with REPLACE and REGEXP_REPLACE
--   8. Save cleaned data into a new table
-- ============================================================================
