-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 9: Indexing & Query Plan Optimization with EXPLAIN Evidence
-- Covers:
--   1. Composite index for multi-column filtering (category + unit_price)
--   2. Covering index / Sorting optimization for buyer order history
--   3. FULLTEXT search indexing for produce catalog lookup
--   4. Index write overhead & maintenance cost benchmark script
-- ==============================================================================

USE agriconnect;

-- Drop test indexes if already present for idempotent execution
DROP INDEX IF EXISTS idx_products_cat_price ON products;
DROP INDEX IF EXISTS idx_orders_buyer_date ON orders;
DROP INDEX IF EXISTS ft_product_name ON products;

-- ------------------------------------------------------------------------------
-- 1. COMPOSITE INDEX OPTIMIZATION (Category + Price Filter)
-- Common use case: Buyer browses specific food category with price ceiling
-- ------------------------------------------------------------------------------

-- Baseline Query (Before Index):
-- Expected Plan: type = ALL (Full Table Scan), rows = total products in table
EXPLAIN SELECT product_id, product_name, category, unit_price, stock_qty 
FROM products 
WHERE category = 'FRUIT' AND unit_price <= 50000.00;

-- Create Composite Index matching the Left-to-Right equality + range rule
CREATE INDEX idx_products_cat_price ON products(category, unit_price);

-- Optimized Query Plan (After Index):
-- Expected Plan: type = range, key = idx_products_cat_price, rows examined greatly reduced!
EXPLAIN SELECT product_id, product_name, category, unit_price, stock_qty 
FROM products 
WHERE category = 'FRUIT' AND unit_price <= 50000.00;


-- ------------------------------------------------------------------------------
-- 2. BUYER ORDER HISTORY OPTIMIZATION (Index Sort Elimination)
-- Common use case: Mobile app "My Orders" tab displaying customer history sorted by date
-- ------------------------------------------------------------------------------

-- Baseline Query (Before Index):
-- Expected Plan: type = ref (on buyer_id FK), Extra = Using filesort
EXPLAIN SELECT order_id, buyer_id, order_date, status, total_amount 
FROM orders 
WHERE buyer_id = 28 
ORDER BY order_date DESC;

-- Create Composite Index on filter + sort column in matching descending order
CREATE INDEX idx_orders_buyer_date ON orders(buyer_id, order_date DESC);

-- Optimized Query Plan (After Index):
-- Expected Plan: type = ref, key = idx_orders_buyer_date, Extra = backward index scan / NO filesort!
EXPLAIN SELECT order_id, buyer_id, order_date, status, total_amount 
FROM orders 
WHERE buyer_id = 28 
ORDER BY order_date DESC;


-- ------------------------------------------------------------------------------
-- 3. FULLTEXT SEARCH FOR PRODUCE CATALOG
-- Common use case: Buyers searching by vernacular name (e.g., 'Matooke', 'Avocado', 'Kaiso')
-- Regular LIKE '%matooke%' causes full table scans and cannot use B-tree indexes
-- ------------------------------------------------------------------------------

-- Baseline Substring Search:
EXPLAIN SELECT product_id, product_name, category, unit_price 
FROM products 
WHERE product_name LIKE '%Matooke%';

-- Add FULLTEXT Inverted Index
ALTER TABLE products ADD FULLTEXT ft_product_name (product_name);

-- Optimized FULLTEXT Search:
-- Expected Plan: type = fulltext, key = ft_product_name
EXPLAIN SELECT product_id, product_name, category, unit_price 
FROM products 
WHERE MATCH(product_name) AGAINST('Matooke');

-- Execute Fulltext Search
SELECT product_id, product_name, category, unit_price, stock_qty 
FROM products 
WHERE MATCH(product_name) AGAINST('Matooke');


-- ------------------------------------------------------------------------------
-- 4. INDEX COST AWARENESS (Insert Speed Benchmark Demonstration)
-- Demonstrates the write-amplification trade-off of maintaining secondary indexes
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS benchmark_no_index;
DROP TABLE IF EXISTS benchmark_indexed;

CREATE TABLE benchmark_no_index (
    id INT AUTO_INCREMENT PRIMARY KEY,
    val_int INT,
    val_str VARCHAR(50),
    created_at DATETIME
) ENGINE=InnoDB;

CREATE TABLE benchmark_indexed (
    id INT AUTO_INCREMENT PRIMARY KEY,
    val_int INT,
    val_str VARCHAR(50),
    created_at DATETIME,
    INDEX idx_val_int (val_int),
    INDEX idx_val_str (val_str),
    INDEX idx_created (created_at)
) ENGINE=InnoDB;

DROP PROCEDURE IF EXISTS benchmark_insert_cost;

DELIMITER //
CREATE PROCEDURE benchmark_insert_cost(IN p_rows INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE t1, t2 BIGINT;
    DECLARE elapsed_no_idx, elapsed_idx DECIMAL(10,4);

    -- Benchmark unindexed table
    SET t1 = BENCHMARK(0, 1); -- reset
    SET @start_time = CURRENT_TIMESTAMP(6);
    START TRANSACTION;
    WHILE i < p_rows DO
        INSERT INTO benchmark_no_index (val_int, val_str, created_at)
        VALUES (i, CONCAT('SampleProduce_', i), NOW());
        SET i = i + 1;
    END WHILE;
    COMMIT;
    SET @end_time = CURRENT_TIMESTAMP(6);
    SET elapsed_no_idx = TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000000.0;

    -- Benchmark indexed table
    SET i = 0;
    SET @start_time = CURRENT_TIMESTAMP(6);
    START TRANSACTION;
    WHILE i < p_rows DO
        INSERT INTO benchmark_indexed (val_int, val_str, created_at)
        VALUES (i, CONCAT('SampleProduce_', i), NOW());
        SET i = i + 1;
    END WHILE;
    COMMIT;
    SET @end_time = CURRENT_TIMESTAMP(6);
    SET elapsed_idx = TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) / 1000000.0;

    -- Clean up temporary benchmark tables
    DROP TABLE benchmark_no_index;
    DROP TABLE benchmark_indexed;

    SELECT 
        p_rows AS rows_inserted,
        elapsed_no_idx AS seconds_unindexed,
        elapsed_idx AS seconds_with_3_indexes,
        ROUND((elapsed_idx - elapsed_no_idx) / elapsed_no_idx * 100, 1) AS pct_write_overhead_penalty;
END //
DELIMITER ;

-- Test benchmark insertion with 5,000 rows
CALL benchmark_insert_cost(5000);
