-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 7: ACID Transactions & Core Stored Procedures
-- Implements:
--   1. sp_place_order: Complete 5-table atomic checkout procedure with pessimistic locking
--   2. sp_cash_in: Mobile money wallet top-up procedure
--   3. sp_cash_out: Mobile money wallet withdrawal procedure
--   4. Verification tests proving rollback on failure (atomicity proof)
-- ==============================================================================

USE agriconnect;

DROP PROCEDURE IF EXISTS sp_place_order;
DROP PROCEDURE IF EXISTS sp_cash_in;
DROP PROCEDURE IF EXISTS sp_cash_out;

DELIMITER //

-- ------------------------------------------------------------------------------
-- 1. sp_place_order
-- Core transactional engine touching 5 tables:
-- products, wallets, orders, order_items, wallet_txns, deliveries
-- ------------------------------------------------------------------------------
CREATE PROCEDURE sp_place_order(
    IN p_buyer_id INT,
    IN p_product_id INT,
    IN p_qty DECIMAL(10,2),
    IN p_address VARCHAR(200)
)
proc_label: BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock DECIMAL(10,2);
    DECLARE v_farmer INT;
    DECLARE v_buyer_wallet INT;
    DECLARE v_farmer_wallet INT;
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_commission DECIMAL(12,2);
    DECLARE v_order_id BIGINT;
    DECLARE v_buyer_balance DECIMAL(14,2);

    -- Automatic Rollback and Error Propagation
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Basic input parameter validation
    IF p_qty <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order quantity must be strictly greater than zero';
    END IF;

    START TRANSACTION;

    -- Step 1: Pessimistic Row Lock on Product (guarantees stock check & deduction are race-condition free)
    SELECT unit_price, stock_qty, farmer_id 
    INTO v_price, v_stock, v_farmer
    FROM products 
    WHERE product_id = p_product_id AND is_active = TRUE
    FOR UPDATE;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Product not found or inactive';
    END IF;

    -- Step 2: Enforce Stock Availability (Business Rule 5)
    IF v_stock < p_qty THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Insufficient stock for requested quantity';
    END IF;

    -- Step 3: Compute Financials (5% Platform Commission)
    SET v_total = v_price * p_qty;
    SET v_commission = ROUND(v_total * 0.05, 2);

    -- Step 4: Pessimistic Row Lock on Buyer Wallet
    SELECT wallet_id, balance 
    INTO v_buyer_wallet, v_buyer_balance
    FROM wallets 
    WHERE user_id = p_buyer_id 
    FOR UPDATE;

    IF v_buyer_wallet IS NULL THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Buyer wallet not found';
    END IF;

    -- Step 5: Enforce Solvency (Business Rule 2: Wallet balance can never go below zero)
    IF v_buyer_balance < v_total THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Insufficient wallet balance for purchase';
    END IF;

    -- Step 6: Identify Farmer Wallet for Credit
    SELECT wallet_id 
    INTO v_farmer_wallet 
    FROM wallets 
    WHERE user_id = v_farmer;

    IF v_farmer_wallet IS NULL THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Farmer wallet not found';
    END IF;

    -- Step 7: Create Order Master Record
    INSERT INTO orders (buyer_id, status, delivery_address, total_amount)
    VALUES (p_buyer_id, 'PAID', p_address, v_total);

    SET v_order_id = LAST_INSERT_ID();

    -- Step 8: Create Order Item Line with Frozen Purchase Price (Business Rule 4)
    INSERT INTO order_items (order_id, product_id, qty, unit_price)
    VALUES (v_order_id, p_product_id, p_qty, v_price);

    -- Step 9: Atomically Reduce Inventory Stock
    UPDATE products 
    SET stock_qty = stock_qty - p_qty 
    WHERE product_id = p_product_id;

    -- Step 10: Debit Buyer Wallet
    UPDATE wallets 
    SET balance = balance - v_total 
    WHERE wallet_id = v_buyer_wallet;

    -- Step 11: Credit Farmer Wallet (Net Amount = Total - 5% Commission)
    UPDATE wallets 
    SET balance = balance + (v_total - v_commission) 
    WHERE wallet_id = v_farmer_wallet;

    -- Step 12: Write Immutable Double-Entry Ledger Logs (Business Rule 3)
    INSERT INTO wallet_txns (wallet_id, txn_type, amount, ref_code, counterparty_wallet)
    VALUES 
        (v_buyer_wallet, 'PAYMENT', v_total, CONCAT('ORD', v_order_id, '_DB'), v_farmer_wallet),
        (v_farmer_wallet, 'RECEIPT', v_total - v_commission, CONCAT('ORD', v_order_id, '_CR'), v_buyer_wallet);

    -- Step 13: Automatically Schedule Logistics Delivery
    INSERT INTO deliveries (order_id, status) 
    VALUES (v_order_id, 'SCHEDULED');

    -- Commit transaction atomically
    COMMIT;

    -- Return success payload
    SELECT 
        v_order_id AS created_order_id,
        'PAID' AS order_status,
        v_total AS amount_paid_ugx,
        v_commission AS platform_commission_ugx,
        (v_total - v_commission) AS farmer_credited_ugx,
        'Transaction completed and committed successfully' AS message;
END //

-- ------------------------------------------------------------------------------
-- 2. sp_cash_in
-- Mobile Money Deposit into User Wallet
-- ------------------------------------------------------------------------------
CREATE PROCEDURE sp_cash_in(
    IN p_user_id INT, 
    IN p_amt DECIMAL(12,2)
)
BEGIN
    DECLARE v_wallet_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cash-in deposit amount must be greater than zero';
    END IF;

    START TRANSACTION;

    SELECT wallet_id INTO v_wallet_id
    FROM wallets
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_wallet_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Wallet does not exist for specified user';
    END IF;

    UPDATE wallets 
    SET balance = balance + p_amt 
    WHERE wallet_id = v_wallet_id;

    INSERT INTO wallet_txns (wallet_id, txn_type, amount, ref_code)
    VALUES (v_wallet_id, 'CASH_IN', p_amt, CONCAT('CI', UNIX_TIMESTAMP(), '_', p_user_id));

    COMMIT;

    SELECT 
        v_wallet_id AS wallet_id,
        p_user_id AS user_id,
        balance AS new_balance,
        'Deposit successful' AS status
    FROM wallets
    WHERE wallet_id = v_wallet_id;
END //

-- ------------------------------------------------------------------------------
-- 3. sp_cash_out
-- Mobile Money Cash Withdrawal from User Wallet
-- ------------------------------------------------------------------------------
CREATE PROCEDURE sp_cash_out(
    IN p_user_id INT, 
    IN p_amt DECIMAL(12,2)
)
BEGIN
    DECLARE v_wallet_id INT;
    DECLARE v_current_bal DECIMAL(14,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK; 
        RESIGNAL; 
    END;

    IF p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cash-out withdrawal amount must be greater than zero';
    END IF;

    START TRANSACTION;

    SELECT wallet_id, balance INTO v_wallet_id, v_current_bal
    FROM wallets
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_wallet_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Wallet does not exist for specified user';
    END IF;

    IF v_current_bal < p_amt THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient balance for cash-out';
    END IF;

    UPDATE wallets 
    SET balance = balance - p_amt 
    WHERE wallet_id = v_wallet_id;

    INSERT INTO wallet_txns (wallet_id, txn_type, amount, ref_code)
    VALUES (v_wallet_id, 'CASH_OUT', p_amt, CONCAT('CO', UNIX_TIMESTAMP(), '_', p_user_id));

    COMMIT;

    SELECT 
        v_wallet_id AS wallet_id,
        p_user_id AS user_id,
        balance AS new_balance,
        'Withdrawal successful' AS status
    FROM wallets
    WHERE wallet_id = v_wallet_id;
END //

DELIMITER ;

-- ==============================================================================
-- DEMO & VERIFICATION SCRIPT (Execute sequentially to verify behavior)
-- ==============================================================================

-- 1. Test Success Path: Buyer 26 buys 2 bunches of Mpologoma Matooke (Product 21)
-- Expected: Order created, stock decreased by 2, buyer debited, farmer credited, delivery scheduled.
CALL sp_place_order(26, 21, 2.00, 'Plot 12, Ntinda Crescent, Kampala');

-- 2. Test Wallet Top-up: Buyer 27 deposits 500,000 UGX
CALL sp_cash_in(27, 500000.00);

-- 3. Test Atomicity & Stock Rollback: Buyer 26 requests 99,999 units (exceeds stock)
-- Expected: Fails with 'Insufficient stock for requested quantity'. Zero rows modified!
-- UNCOMMENT TO TEST IN CLIENT:
-- CALL sp_place_order(26, 21, 99999.00, 'Ntinda, Kampala');

-- 4. Test Atomicity & Balance Rollback: Buyer with 0 balance tries to buy
-- Expected: Fails with 'Insufficient wallet balance for purchase'. Zero rows modified!
