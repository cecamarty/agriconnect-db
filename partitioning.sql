-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 10: Physical Design, Query Rewriting & Range Partitioning
-- Demonstrates:
--   1. Sargable query rewriting to restore index usage
--   2. Denormalized analytics table: fact_order_lines
--   3. RANGE partitioning by YEAR(order_date) with partition key in Primary Key
--   4. Partition pruning proof (EXPLAIN partitions)
--   5. Bulk load generator stored procedure (seed_history)
-- ==============================================================================

USE agriconnect;

-- ------------------------------------------------------------------------------
-- 1. SARGABLE QUERY REWRITE
-- Anti-pattern: wrapping indexed columns in functions disables B-tree index lookup
-- ------------------------------------------------------------------------------

-- SLOW (Non-sargable): YEAR() and MONTH() functions prevent index usage, forcing table scan
EXPLAIN SELECT * FROM orders 
WHERE YEAR(order_date) = 2025 AND MONTH(order_date) = 1;

-- FAST (Sargable range): Comparison operators on raw column allow B-tree range scan
EXPLAIN SELECT * FROM orders 
WHERE order_date >= '2025-01-01 00:00:00' AND order_date < '2025-02-01 00:00:00';


-- ------------------------------------------------------------------------------
-- 2. PARTITIONED ANALYTICS TABLE: fact_order_lines
-- Architectural Rule: MySQL InnoDB requires that every unique key / primary key on a
-- partitioned table MUST contain every column in the table's partitioning expression.
-- Therefore, MySQL partitioned tables cannot maintain foreign keys pointing to
-- external tables. This justifies the denormalized analytics star schema.
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS fact_order_lines;

CREATE TABLE fact_order_lines (
    order_id BIGINT NOT NULL,
    order_date DATETIME NOT NULL,
    buyer_id INT,
    farmer_id INT,
    product_id INT,
    category VARCHAR(20),
    qty DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    line_total DECIMAL(12,2),
    PRIMARY KEY (order_id, order_date) -- Partition column order_date MUST be in PK
) ENGINE=InnoDB
PARTITION BY RANGE (YEAR(order_date)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION pmax  VALUES LESS THAN MAXVALUE
);

-- ------------------------------------------------------------------------------
-- 3. ETL POPULATION FROM OPERATIONAL OLTP TABLES
-- Extracts historical order lines and populates the partitioned reporting table
-- ------------------------------------------------------------------------------
INSERT INTO fact_order_lines (
    order_id, order_date, buyer_id, farmer_id,
    product_id, category, qty, unit_price, line_total
)
SELECT 
    o.order_id,
    o.order_date,
    o.buyer_id,
    p.farmer_id,
    p.product_id,
    p.category,
    oi.qty,
    oi.unit_price,
    oi.line_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id;


-- ------------------------------------------------------------------------------
-- 4. PROOF OF PARTITION PRUNING
-- Explains how MySQL scans ONLY partition 'p2025' and completely prunes others
-- ------------------------------------------------------------------------------
EXPLAIN
SELECT 
    category,
    COUNT(*) AS total_sales_count,
    SUM(line_total) AS total_revenue
FROM fact_order_lines
WHERE order_date >= '2025-01-01' AND order_date < '2025-02-01'
GROUP BY category;


-- ------------------------------------------------------------------------------
-- 5. LOAD GENERATOR PROCEDURE: seed_history
-- Generates bulk historical sales data to validate scaling and benchmark query speed
-- ------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS seed_history;

DELIMITER //
CREATE PROCEDURE seed_history(IN n INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_days INT;
    DECLARE v_qty DECIMAL(10,2);
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_cat VARCHAR(20);

    -- Speed up mass ingestion inside a single transaction batch
    START TRANSACTION;
    WHILE i < n DO
        SET v_days = FLOOR(RAND() * 1000); -- spread across ~3 years
        SET v_qty = 1 + FLOOR(RAND() * 20);
        SET v_price = 5000 + FLOOR(RAND() * 50000);
        
        SET v_cat = CASE FLOOR(RAND() * 6)
            WHEN 0 THEN 'GRAIN'
            WHEN 1 THEN 'FRUIT'
            WHEN 2 THEN 'VEGETABLE'
            WHEN 3 THEN 'TUBER'
            WHEN 4 THEN 'LIVESTOCK'
            ELSE 'OTHER'
        END;

        INSERT INTO fact_order_lines (
            order_id, order_date, buyer_id, farmer_id,
            product_id, category, qty, unit_price, line_total
        )
        VALUES (
            900000 + i,
            DATE_SUB(NOW(), INTERVAL v_days DAY),
            26 + FLOOR(RAND() * 25), -- random buyer
            1 + FLOOR(RAND() * 25),  -- random farmer
            1 + FLOOR(RAND() * 100), -- random product
            v_cat,
            v_qty,
            v_price,
            v_qty * v_price
        );

        SET i = i + 1;
        
        -- Commit every 10,000 rows to prevent undo buffer overflow
        IF (i % 10000 = 0) THEN
            COMMIT;
            START TRANSACTION;
        END IF;
    END WHILE;
    COMMIT;
    
    SELECT CONCAT('Successfully inserted ', n, ' synthetic analytical order records.') AS status;
END //
DELIMITER ;

-- Generate 5,000 synthetic rows for test execution (can scale up to 200,000)
CALL seed_history(5000);

-- Verify distribution of data across partitions
SELECT 
    PARTITION_NAME, 
    TABLE_ROWS, 
    DATA_LENGTH, 
    INDEX_LENGTH
FROM information_schema.PARTITIONS
WHERE TABLE_NAME = 'fact_order_lines' 
  AND TABLE_SCHEMA = 'agriconnect';
