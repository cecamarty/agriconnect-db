-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 3: Database Schema Definition (DDL)
-- Target DBMS: MySQL 8.0+
-- Character Set: utf8mb4 / utf8mb4_unicode_ci
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS agriconnect CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE agriconnect;

-- Drop dependent tables in reverse dependency order for clean reinstalls
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS wallet_txns;
DROP TABLE IF EXISTS wallets;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS towns;

-- ------------------------------------------------------------------------------
-- 1. TOWNS
-- Reference table for geographic locations, districts, and logistics routes
-- ------------------------------------------------------------------------------
CREATE TABLE towns (
    town_id INT AUTO_INCREMENT PRIMARY KEY,
    town_name VARCHAR(60) NOT NULL UNIQUE,
    district VARCHAR(60) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 2. USERS
-- Core user entity representing Farmers, Buyers, or Both (Dual Role)
-- Identified uniquely by Ugandan phone numbers (e.g. 256XXXXXXXXX)
-- ------------------------------------------------------------------------------
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(13) NOT NULL UNIQUE, -- E.164 Ugandan format: 256XXXXXXXXX
    email VARCHAR(120) UNIQUE,
    role ENUM('FARMER', 'BUYER', 'BOTH') NOT NULL DEFAULT 'BUYER',
    town_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_town FOREIGN KEY (town_id) REFERENCES towns(town_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 3. WALLETS
-- Digital wallet for every user (1:1 strict relationship)
-- Business Rule 2: Balance can never go below zero (enforced by CHECK constraint)
-- ------------------------------------------------------------------------------
CREATE TABLE wallets (
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE, -- Ensures 1:1 relationship with users
    balance DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_wallet_balance CHECK (balance >= 0),
    CONSTRAINT fk_wallets_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 4. WALLET TRANSACTIONS (WALLET_TXNS)
-- Immutable ledger tracking all money movements (cash-in, cash-out, payment, receipt)
-- Weak entity dependent on WALLETS
-- ------------------------------------------------------------------------------
CREATE TABLE wallet_txns (
    txn_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    wallet_id INT NOT NULL,
    txn_type ENUM('CASH_IN', 'CASH_OUT', 'PAYMENT', 'RECEIPT') NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    ref_code VARCHAR(30) UNIQUE,
    counterparty_wallet INT NULL,
    txn_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_txn_amount CHECK (amount > 0),
    CONSTRAINT fk_txns_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_txns_counterparty FOREIGN KEY (counterparty_wallet) REFERENCES wallets(wallet_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 5. PRODUCTS
-- Agricultural commodities listed by farmers
-- Flexible categorical divisions & standard regional trade units
-- ------------------------------------------------------------------------------
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    farmer_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    category ENUM('GRAIN', 'FRUIT', 'VEGETABLE', 'TUBER', 'LIVESTOCK', 'OTHER') NOT NULL,
    unit ENUM('kg', 'crate', 'bag', 'bunch', 'litre') NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    stock_qty DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_unit_price CHECK (unit_price > 0),
    CONSTRAINT chk_stock_qty CHECK (stock_qty >= 0),
    CONSTRAINT fk_products_farmer FOREIGN KEY (farmer_id) REFERENCES users(user_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 6. ORDERS
-- Purchase orders created by buyers
-- ------------------------------------------------------------------------------
CREATE TABLE orders (
    order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    buyer_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('PENDING', 'PAID', 'DISPATCHED', 'DELIVERED', 'CANCELLED') DEFAULT 'PENDING',
    delivery_address VARCHAR(200) NOT NULL,
    total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT chk_total_amount CHECK (total_amount >= 0),
    CONSTRAINT fk_orders_buyer FOREIGN KEY (buyer_id) REFERENCES users(user_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 7. ORDER_ITEMS
-- Resolves M:N relationship between ORDERS and PRODUCTS
-- Weak entity dependent on ORDERS
-- Business Rule 4: Price is frozen at purchase time; line_total generated & stored
-- ------------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    qty DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL, -- Historical price frozen at purchase moment
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (qty * unit_price) STORED,
    CONSTRAINT chk_item_qty CHECK (qty > 0),
    CONSTRAINT chk_item_unit_price CHECK (unit_price > 0),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 8. DELIVERIES
-- Logistics and dispatch tracking (1:0..1 relationship with orders)
-- ------------------------------------------------------------------------------
CREATE TABLE deliveries (
    delivery_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE, -- 1:1 with orders
    driver_name VARCHAR(100),
    driver_phone VARCHAR(13),
    status ENUM('SCHEDULED', 'IN_TRANSIT', 'DONE', 'FAILED') DEFAULT 'SCHEDULED',
    dispatched_at DATETIME NULL,
    delivered_at DATETIME NULL,
    CONSTRAINT fk_deliveries_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 9. REVIEWS
-- Feedback rating (1-5 stars) and comments on purchased products
-- Associative entity resolving M:N between BUYERS and PRODUCTS
-- Business Rule 8: Unique constraint prevents multiple ratings per product per buyer
-- ------------------------------------------------------------------------------
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    buyer_id INT NOT NULL,
    product_id INT NOT NULL,
    rating TINYINT NOT NULL,
    comment VARCHAR(300),
    review_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT uq_buyer_product_review UNIQUE (buyer_id, product_id),
    CONSTRAINT fk_reviews_buyer FOREIGN KEY (buyer_id) REFERENCES users(user_id) ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON UPDATE CASCADE
) ENGINE=InnoDB;
