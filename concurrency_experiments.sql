-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 8: Concurrency, Locking, and Deadlock Experiments
-- Demonstrates:
--   Experiment A: Lost Updates / Overselling bug (WITHOUT locking)
--   Experiment B: Concurrency resolution with SELECT ... FOR UPDATE
--   Experiment C: Deadlock detection & cycle rollback (ERROR 1213)
--   Experiment D: Transaction isolation level behavior (REPEATABLE READ vs READ COMMITTED)
-- ==============================================================================

USE agriconnect;

-- ------------------------------------------------------------------------------
-- EXPERIMENT A: Oversell Bug Demonstration (sp_place_order_nolock)
-- Demonstrates the Race Condition / Lost Update when pessimistic locks are omitted
-- ------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_place_order_nolock;

DELIMITER //
CREATE PROCEDURE sp_place_order_nolock(
    IN p_buyer_id INT,
    IN p_product_id INT,
    IN p_qty DECIMAL(10,2),
    IN p_address VARCHAR(200)
)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock DECIMAL(10,2);
    DECLARE v_farmer INT;
    DECLARE v_buyer_wallet INT;
    DECLARE v_farmer_wallet INT;
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_commission DECIMAL(12,2);
    DECLARE v_order_id BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- VULNERABLE READ: No 'FOR UPDATE' clause!
    -- Session 1 and Session 2 both read the SAME stock before either commits!
    SELECT unit_price, stock_qty, farmer_id 
    INTO v_price, v_stock, v_farmer
    FROM products 
    WHERE product_id = p_product_id;

    -- Artificial delay (or concurrent arrival) allows Session 2 to read the same old stock
    SELECT SLEEP(2);

    IF v_stock < p_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock (nolock)';
    END IF;

    SET v_total = v_price * p_qty;
    SET v_commission = ROUND(v_total * 0.05, 2);

    SELECT wallet_id INTO v_buyer_wallet FROM wallets WHERE user_id = p_buyer_id;
    SELECT wallet_id INTO v_farmer_wallet FROM wallets WHERE user_id = v_farmer;

    INSERT INTO orders (buyer_id, status, delivery_address, total_amount)
    VALUES (p_buyer_id, 'PAID', p_address, v_total);
    SET v_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (order_id, product_id, qty, unit_price)
    VALUES (v_order_id, p_product_id, p_qty, v_price);

    -- DEDUCTION: If both sessions read v_stock = 1, both subtract 1 -> stock becomes -1!
    UPDATE products SET stock_qty = stock_qty - p_qty WHERE product_id = p_product_id;
    UPDATE wallets SET balance = balance - v_total WHERE wallet_id = v_buyer_wallet;
    UPDATE wallets SET balance = balance + (v_total - v_commission) WHERE wallet_id = v_farmer_wallet;

    COMMIT;
END //
DELIMITER ;

-- Setup Test Commodity for Experiment A & B:
-- Set product 72 (Ginger Rhizomes) to exactly 1 unit left
UPDATE products SET stock_qty = 1.00 WHERE product_id = 72;

/*
TEST PROTOCOL FOR EXPERIMENT A (Open two terminal tabs / Workbench connections):
--------------------------------------------------------------------------------
Session 1:
   CALL sp_place_order_nolock(26, 72, 1.00, 'Kampala Session 1');

Session 2 (Run immediately within 2 seconds):
   CALL sp_place_order_nolock(27, 72, 1.00, 'Kampala Session 2');

Result in Experiment A:
   Both queries return success!
   Verify with: SELECT product_id, product_name, stock_qty FROM products WHERE product_id = 72;
   Observed stock_qty: -1.00 (VIOLATION of Business Rule 5: Overselling occurred!)
*/


-- ------------------------------------------------------------------------------
-- EXPERIMENT B: The Fix with SELECT ... FOR UPDATE
-- ------------------------------------------------------------------------------
-- Reset test commodity stock back to 1.00
UPDATE products SET stock_qty = 1.00 WHERE product_id = 72;

/*
TEST PROTOCOL FOR EXPERIMENT B:
--------------------------------------------------------------------------------
Session 1:
   CALL sp_place_order(26, 72, 1.00, 'Kampala Protected 1');

Session 2 (Run immediately while Session 1 is in-flight):
   CALL sp_place_order(27, 72, 1.00, 'Kampala Protected 2');

Result in Experiment B:
   Session 1 obtains an exclusive X-lock on product 72 and completes successfully.
   Session 2 blocks waiting for the lock on product 72.
   Once Session 1 commits, Session 2 acquires the lock, reads stock_qty = 0.00,
   and fails with: "Error Code: 1644. Insufficient stock for requested quantity".
   Verify: SELECT stock_qty FROM products WHERE product_id = 72; -> Remains exactly 0.00!
*/


-- ------------------------------------------------------------------------------
-- EXPERIMENT C: Deadlock Demonstration (ERROR 1213)
-- Two sessions performing opposing wallet transfers concurrently
-- ------------------------------------------------------------------------------

/*
TEST PROTOCOL FOR EXPERIMENT C:
--------------------------------------------------------------------------------
Session 1:
   START TRANSACTION;
   UPDATE wallets SET balance = balance - 1000 WHERE wallet_id = 1;
   -- Keep Session 1 transaction open...

Session 2:
   START TRANSACTION;
   UPDATE wallets SET balance = balance - 1000 WHERE wallet_id = 2;
   -- Keep Session 2 transaction open...

Session 1 (Next Step):
   UPDATE wallets SET balance = balance + 1000 WHERE wallet_id = 2;
   -- Session 1 blocks, waiting for lock on wallet_id = 2 held by Session 2...

Session 2 (Next Step):
   UPDATE wallets SET balance = balance + 1000 WHERE wallet_id = 1;
   -- Creates a circular dependency wait-for graph!

Result:
   MySQL InnoDB Deadlock Detector fires immediately:
   "ERROR 1213 (40010): Deadlock found when trying to get lock; try restarting transaction"
   InnoDB aborts and rolls back the transaction with the smaller undo log (the victim),
   allowing the other session to proceed and COMMIT!

   Inspection command to view InnoDB deadlock telemetry:
   SHOW ENGINE INNODB STATUS\G
*/


-- ------------------------------------------------------------------------------
-- EXPERIMENT D: Transaction Isolation Levels (REPEATABLE READ vs READ COMMITTED)
-- ------------------------------------------------------------------------------

-- Check default isolation level
SELECT @@transaction_isolation; -- Default in MySQL 8 is REPEATABLE-READ

/*
REPEATABLE READ Experiment (Consistent Non-Locking Snapshot Read):
Session 1:
   START TRANSACTION;
   SELECT balance FROM wallets WHERE wallet_id = 1; -- Example: 1,500,000

Session 2:
   UPDATE wallets SET balance = balance + 50000 WHERE wallet_id = 1;
   COMMIT;

Session 1 (Same transaction):
   SELECT balance FROM wallets WHERE wallet_id = 1; 
   -- Still returns 1,500,000! (Consistent MVCC Read View established at first read)
   COMMIT;

READ COMMITTED Experiment (New snapshot per SQL statement):
Session 1:
   SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
   START TRANSACTION;
   SELECT balance FROM wallets WHERE wallet_id = 1;

Session 2:
   UPDATE wallets SET balance = balance + 25000 WHERE wallet_id = 1;
   COMMIT;

Session 1:
   SELECT balance FROM wallets WHERE wallet_id = 1;
   -- Immediately sees updated balance! (Non-repeatable read phenomenon permitted in READ COMMITTED)
   COMMIT;
*/
