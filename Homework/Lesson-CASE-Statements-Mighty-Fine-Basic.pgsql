-- ============================================================================
-- LESSON: Basic CASE Statements (Mighty Fine Burgers)
-- Course: MS 3083
-- Audience: First-year students
-- ============================================================================
-- CASE lets you return different values based on conditions.
-- Think of it like: IF this is true, show this; otherwise show that.
-- ============================================================================

-- Optional: make sure your schema is available
SET search_path TO mightyfine, public;


-- ============================================================================
-- EXAMPLE 1: Label menu item prices
-- Goal: Create a simple price category for each menu item.
-- ============================================================================
SELECT
    menu_item_id,
    item_name,
    price,
    CASE
        WHEN price < 5 THEN 'Budget'
        WHEN price >= 5 AND price <= 9 THEN 'Standard'
        ELSE 'Premium'
    END AS price_category
FROM mightyfine.menu_items
ORDER BY price;


-- ============================================================================
-- EXAMPLE 2: Translate payment codes into friendly labels
-- Goal: Show a nicer description for each sale's payment_type.
-- ============================================================================
SELECT
    sale_id,
    sale_date,
    payment_type,
    CASE
        WHEN payment_type = 'card' THEN 'Paid with Card'
        WHEN payment_type = 'cash' THEN 'Paid with Cash'
        ELSE 'Other Payment'
    END AS payment_label
FROM mightyfine.sales
ORDER BY sale_id;


-- ============================================================================
-- EXAMPLE 3: Inventory status using CASE
-- Goal: Flag ingredients as low stock or okay based on reorder_level.
-- ============================================================================
SELECT
    i.ingredient_name,
    inv.quantity,
    inv.reorder_level,
    CASE
        WHEN inv.quantity < inv.reorder_level THEN 'LOW - Reorder Now'
        WHEN inv.quantity = inv.reorder_level THEN 'At Reorder Level'
        ELSE 'Stock OK'
    END AS inventory_status
FROM mightyfine.inventory AS inv
JOIN mightyfine.ingredients AS i
    ON inv.ingredient_id = i.ingredient_id
ORDER BY i.ingredient_name;


-- ============================================================================
-- QUICK REVIEW:
-- 1) CASE starts with CASE and ends with END.
-- 2) Each WHEN is a condition.
-- 3) ELSE is optional, but strongly recommended.
-- 4) The result is usually given a column name with AS.
-- ============================================================================
