-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Master Execution Script (run_all.sql)
-- Orchestrates the entire database initialization and verification suite
-- ==============================================================================

SELECT '===================================================' AS 'STEP';
SELECT 'Starting AgriConnect Database Setup...' AS 'STATUS';
SELECT '===================================================' AS 'STEP';

-- 1. Create database and tables
SOURCE schema.sql;

-- 2. Populate realistic seed data
SOURCE seed.sql;

-- 3. Install stored procedures
SOURCE procedures.sql;

-- 4. Install advanced views and reporting queries
SOURCE queries_advanced.sql;

-- 5. Build optimized indexes
SOURCE indexing_optimization.sql;

-- 6. Setup partitioned analytics table
SOURCE partitioning.sql;

-- 7. Apply JSON semi-structured attributes and indexes
SOURCE nosql_json_catalog.sql;

SELECT '===================================================' AS 'STEP';
SELECT 'AgriConnect Database Deployment Complete!' AS 'STATUS';
SELECT '===================================================' AS 'STEP';

-- Quick health check
SELECT 'Towns count' AS metric, COUNT(*) AS total FROM towns
UNION ALL
SELECT 'Users count', COUNT(*) FROM users
UNION ALL
SELECT 'Wallets count', COUNT(*) FROM wallets
UNION ALL
SELECT 'Products count', COUNT(*) FROM products
UNION ALL
SELECT 'Orders count', COUNT(*) FROM orders
UNION ALL
SELECT 'Order items count', COUNT(*) FROM order_items
UNION ALL
SELECT 'Deliveries count', COUNT(*) FROM deliveries
UNION ALL
SELECT 'Reviews count', COUNT(*) FROM reviews
UNION ALL
SELECT 'Fact order lines count', COUNT(*) FROM fact_order_lines;
