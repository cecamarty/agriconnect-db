-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 12: NoSQL Semi-Structured Extension (The Flexible JSON Catalog)
-- Implements Business Rule 9:
--   Products have diverse polymorphic attributes (grains have variety/moisture,
--   livestock has breed/weight_kg, dairy has cold_chain/expiry_days).
--   Avoids sparse schema anti-patterns (e.g. 40 nullable columns) by using
--   MySQL native JSON data types, generated virtual columns, and functional indexing.
-- ==============================================================================

USE agriconnect;

-- ------------------------------------------------------------------------------
-- 1. SCHEMA MIGRATION: ADD JSON ATTRIBUTES COLUMN
-- ------------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE drop_column_if_exists(IN p_table VARCHAR(64), IN p_column VARCHAR(64))
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = DATABASE() AND table_name = p_table AND column_name = p_column
    ) THEN
        SET @sql = CONCAT('ALTER TABLE ', p_table, ' DROP COLUMN ', p_column);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END //
DELIMITER ;

CALL drop_column_if_exists('products', 'organic');
CALL drop_column_if_exists('products', 'weight_kg');
CALL drop_column_if_exists('products', 'attributes');
DROP PROCEDURE IF EXISTS drop_column_if_exists;

ALTER TABLE products 
ADD COLUMN attributes JSON NULL AFTER unit_price;

-- ------------------------------------------------------------------------------
-- 2. POPULATE DIVERSE POLYMORPHIC ATTRIBUTES ACROSS COMMODITIES
-- ------------------------------------------------------------------------------

-- Grain attributes (variety, moisture content, organic certification)
UPDATE products 
SET attributes = JSON_OBJECT(
    'variety', 'Kawanda 4 White',
    'moisture_content_pct', 12.5,
    'grade', 1,
    'organic', 'yes'
) 
WHERE product_id = 2;

-- Fruit attributes (variety, sugar brix, harvest maturity, organic)
UPDATE products 
SET attributes = JSON_OBJECT(
    'variety', 'Mpologoma',
    'ripeness_stage', 'green_unripe',
    'organic', 'yes',
    'handling', 'hang_in_shade'
) 
WHERE product_id = 21;

-- Livestock attributes (breed, live weight kg, vaccination status, tag ID)
UPDATE products 
SET attributes = JSON_OBJECT(
    'breed', 'Ankole Longhorn',
    'weight_kg', 450,
    'vaccination_status', 'FMD_vaccinated',
    'sex', 'steer',
    'tag_id', 'UG-MBR-2024-001'
) 
WHERE product_id = 76;

-- Dairy attributes (cold chain required, fat content, expiry days)
UPDATE products 
SET attributes = JSON_OBJECT(
    'expiry_days', 3,
    'cold_chain', 'yes',
    'butterfat_pct', 4.2,
    'pasteurized', 'no',
    'organic', 'yes'
) 
WHERE product_id = 91;

-- Specialty export crop (Coffee)
UPDATE products 
SET attributes = JSON_OBJECT(
    'variety', 'Arabica SL14/SL28',
    'altitude_masl', 1850,
    'cupping_score', 86.5,
    'process', 'fully_washed',
    'organic', 'yes'
) 
WHERE product_id = 95;


-- ------------------------------------------------------------------------------
-- 3. QUERYING THE SEMI-STRUCTURED JSON DATA
-- Demonstrates JSON_EXTRACT, JSON_UNQUOTE, and the MySQL inline ->> path operator
-- ------------------------------------------------------------------------------

-- A. Query using JSON_EXTRACT & JSON_UNQUOTE
SELECT 
    product_id, 
    product_name, 
    category,
    JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.variety')) AS crop_variety,
    JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.organic')) AS is_organic
FROM products 
WHERE JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.organic')) = 'yes';

-- B. Query using modern MySQL ->> unquoting extraction operator
SELECT 
    product_id, 
    product_name, 
    category,
    attributes->>'$.breed' AS livestock_breed,
    CAST(attributes->>'$.weight_kg' AS UNSIGNED) AS animal_weight_kg
FROM products 
WHERE attributes->>'$.breed' IS NOT NULL;


-- ------------------------------------------------------------------------------
-- 4. VIRTUAL GENERATED COLUMNS & SECONDARY INDEXING
-- Enables high-performance B-tree indexing on JSON attributes without table bloating
-- ------------------------------------------------------------------------------

-- Add virtual column for 'organic' certification
ALTER TABLE products
ADD COLUMN organic VARCHAR(5) 
    GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.organic'))) VIRTUAL,
ADD INDEX idx_organic (organic);

-- Add virtual column for numeric livestock weight
ALTER TABLE products
ADD COLUMN weight_kg DECIMAL(6,2)
    GENERATED ALWAYS AS (CAST(JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.weight_kg')) AS DECIMAL(6,2))) VIRTUAL,
ADD INDEX idx_weight_kg (weight_kg);

-- ------------------------------------------------------------------------------
-- 5. VERIFY QUERY ACCELERATION ON JSON ATTRIBUTES VIA EXPLAIN
-- ------------------------------------------------------------------------------

-- Expected Plan: type = ref, key = idx_organic (index scan rather than full table JSON scan)
EXPLAIN SELECT product_id, product_name, category, unit_price, organic 
FROM products 
WHERE organic = 'yes';

-- Execute indexed query
SELECT product_id, product_name, category, unit_price, organic 
FROM products 
WHERE organic = 'yes';
