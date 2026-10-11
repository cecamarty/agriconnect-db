-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 4: The Query Pack (Basic & Intermediate Business Reports)
-- Contains 16 production-grade SQL queries satisfying all project specifications
-- ==============================================================================

USE agriconnect;

-- ------------------------------------------------------------------------------
-- Query 1: Every farmer and their listed products (INNER JOIN)
-- Business Context: Directory of active suppliers and catalog offerings.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id AS farmer_id,
    u.full_name AS farmer_name,
    u.phone AS farmer_phone,
    t.town_name,
    p.product_id,
    p.product_name,
    p.category,
    p.unit,
    p.unit_price,
    p.stock_qty
FROM users u
JOIN products p ON u.user_id = p.farmer_id
JOIN towns t ON u.town_id = t.town_id
WHERE p.is_active = TRUE
ORDER BY u.full_name, p.product_name;

-- ------------------------------------------------------------------------------
-- Query 2: Buyers with no orders yet (LEFT JOIN + IS NULL / Anti-Join)
-- Business Context: Marketing targets for onboarding promotions & voucher SMS.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id AS buyer_id,
    u.full_name,
    u.phone,
    u.email,
    t.town_name,
    u.created_at
FROM users u
LEFT JOIN orders o ON o.buyer_id = u.user_id
JOIN towns t ON u.town_id = t.town_id
WHERE u.role IN ('BUYER', 'BOTH')
  AND o.order_id IS NULL
ORDER BY u.created_at DESC;

-- ------------------------------------------------------------------------------
-- Query 3: Total spent per buyer on delivered goods (GROUP BY + Aggregate)
-- Business Context: Lifetime value (LTV) calculation for VIP buyer rewards.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.full_name,
    u.phone,
    COUNT(o.order_id) AS delivered_orders_count,
    SUM(o.total_amount) AS lifetime_spend,
    AVG(o.total_amount) AS avg_order_value
FROM users u
JOIN orders o ON o.buyer_id = u.user_id
WHERE o.status = 'DELIVERED'
GROUP BY u.user_id, u.full_name, u.phone
ORDER BY lifetime_spend DESC;

-- ------------------------------------------------------------------------------
-- Query 4: Products never ordered (Subquery with NOT IN)
-- Business Context: Stale inventory identification for promotional discounts.
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    p.stock_qty,
    u.full_name AS farmer_name
FROM products p
JOIN users u ON p.farmer_id = u.user_id
WHERE p.product_id NOT IN (
    SELECT DISTINCT product_id 
    FROM order_items
)
ORDER BY p.category, p.product_name;

-- ------------------------------------------------------------------------------
-- Query 5: Deliveries scheduled but not yet dispatched (NULL check)
-- Business Context: Logistics warehouse queue monitoring for dispatch managers.
-- ------------------------------------------------------------------------------
SELECT 
    o.order_id,
    o.order_date,
    o.buyer_id,
    u.full_name AS buyer_name,
    o.delivery_address,
    d.driver_name,
    d.status AS delivery_status
FROM orders o
LEFT JOIN deliveries d ON d.order_id = o.order_id
JOIN users u ON o.buyer_id = u.user_id
WHERE o.status IN ('PAID', 'PENDING')
  AND (d.dispatched_at IS NULL OR d.status = 'SCHEDULED')
ORDER BY o.order_date ASC;

-- ------------------------------------------------------------------------------
-- Query 6: Average product rating and total review count per product (GROUP BY + LEFT JOIN)
-- Business Context: Product quality reputation index and customer satisfaction.
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(r.review_id) AS total_reviews,
    COALESCE(ROUND(AVG(r.rating), 2), 0.00) AS average_rating,
    MIN(r.rating) AS lowest_rating,
    MAX(r.rating) AS highest_rating
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING total_reviews > 0
ORDER BY average_rating DESC, total_reviews DESC;

-- ------------------------------------------------------------------------------
-- Query 7: High-value orders exceeding 500,000 UGX with item breakdown
-- Business Context: Bulk commercial orders requiring dedicated logistics dispatch.
-- ------------------------------------------------------------------------------
SELECT 
    o.order_id,
    o.order_date,
    u.full_name AS buyer_name,
    o.total_amount,
    COUNT(oi.order_item_id) AS item_lines_count,
    SUM(oi.qty) AS total_units_purchased
FROM orders o
JOIN users u ON o.buyer_id = u.user_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, u.full_name, o.total_amount
HAVING o.total_amount >= 500000.00
ORDER BY o.total_amount DESC;

-- ------------------------------------------------------------------------------
-- Query 8: Order volume and revenue aggregated by Town/Region
-- Business Context: Regional market demand analysis for expansion planning.
-- ------------------------------------------------------------------------------
SELECT 
    t.town_id,
    t.town_name,
    t.district,
    COUNT(DISTINCT u.user_id) AS registered_users,
    COUNT(DISTINCT o.order_id) AS total_orders_placed,
    COALESCE(SUM(o.total_amount), 0.00) AS gross_regional_sales
FROM towns t
LEFT JOIN users u ON t.town_id = u.town_id
LEFT JOIN orders o ON u.user_id = o.buyer_id AND o.status != 'CANCELLED'
GROUP BY t.town_id, t.town_name, t.district
ORDER BY gross_regional_sales DESC;

-- ------------------------------------------------------------------------------
-- Query 9: Low stock inventory warning (Stock < 50 units)
-- Business Context: Automated alert trigger notifying farmers to replenish stock.
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.stock_qty,
    p.unit,
    u.full_name AS farmer_name,
    u.phone AS farmer_phone
FROM products p
JOIN users u ON p.farmer_id = u.user_id
WHERE p.is_active = TRUE 
  AND p.stock_qty <= 50.00
ORDER BY p.stock_qty ASC;

-- ------------------------------------------------------------------------------
-- Query 10: Gross and Net revenue earned by each Farmer (after 5% platform fee)
-- Business Context: Financial settlement validation and farmer payout reconciliation.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id AS farmer_id,
    u.full_name AS farmer_name,
    COUNT(DISTINCT o.order_id) AS fulfilled_orders,
    SUM(oi.line_total) AS gross_revenue,
    ROUND(SUM(oi.line_total) * 0.05, 2) AS platform_commission_5pct,
    ROUND(SUM(oi.line_total) * 0.95, 2) AS farmer_net_earnings
FROM users u
JOIN products p ON u.user_id = p.farmer_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'DELIVERED'
GROUP BY u.user_id, u.full_name
ORDER BY farmer_net_earnings DESC;

-- ------------------------------------------------------------------------------
-- Query 11: Products with high customer satisfaction (Subquery with EXISTS)
-- Business Context: Products that have received at least one 5-star review.
-- ------------------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price
FROM products p
WHERE EXISTS (
    SELECT 1 
    FROM reviews r 
    WHERE r.product_id = p.product_id 
      AND r.rating = 5
)
ORDER BY p.product_name ASC;

-- ------------------------------------------------------------------------------
-- Query 12: Delivery turnaround time in hours for completed orders
-- Business Context: SLA tracking for 3PL logistics dispatch performance.
-- ------------------------------------------------------------------------------
SELECT 
    d.delivery_id,
    d.order_id,
    d.driver_name,
    d.dispatched_at,
    d.delivered_at,
    ROUND(TIMESTAMPDIFF(MINUTE, d.dispatched_at, d.delivered_at) / 60.0, 2) AS transit_time_hours
FROM deliveries d
WHERE d.status = 'DONE'
  AND d.dispatched_at IS NOT NULL 
  AND d.delivered_at IS NOT NULL
ORDER BY transit_time_hours ASC;

-- ------------------------------------------------------------------------------
-- Query 13: Summary breakdown of orders by current fulfillment status
-- Business Context: Operations health monitor dashboard tile.
-- ------------------------------------------------------------------------------
SELECT 
    status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1) AS pct_of_total_orders,
    SUM(total_amount) AS total_value_ugx
FROM orders
GROUP BY status
ORDER BY total_orders DESC;

-- ------------------------------------------------------------------------------
-- Query 14: Top 5 best-selling agricultural categories by total quantity sold
-- Business Context: Commodity market trade volume index.
-- ------------------------------------------------------------------------------
SELECT 
    p.category,
    COUNT(DISTINCT oi.product_id) AS distinct_products_sold,
    SUM(oi.qty) AS total_units_sold,
    SUM(oi.line_total) AS total_gross_sales
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'DELIVERED'
GROUP BY p.category
ORDER BY total_gross_sales DESC
LIMIT 5;

-- ------------------------------------------------------------------------------
-- Query 15: Cross-check wallet balance vs. recorded transaction history
-- Business Context: Financial integrity audit detecting ledger discrepancies.
-- ------------------------------------------------------------------------------
SELECT 
    w.wallet_id,
    u.full_name,
    w.balance AS current_balance,
    COALESCE(SUM(CASE 
        WHEN wt.txn_type IN ('CASH_IN', 'RECEIPT') THEN wt.amount
        WHEN wt.txn_type IN ('CASH_OUT', 'PAYMENT') THEN -wt.amount
        ELSE 0 
    END), 0.00) AS net_ledger_balance,
    COUNT(wt.txn_id) AS total_txns_logged
FROM wallets w
JOIN users u ON w.user_id = u.user_id
LEFT JOIN wallet_txns wt ON w.wallet_id = wt.wallet_id
GROUP BY w.wallet_id, u.full_name, w.balance
ORDER BY w.wallet_id ASC;

-- ------------------------------------------------------------------------------
-- Query 16: Farmers who also buy produce on the platform (Dual-Role activity)
-- Business Context: Ecosystem stickiness and circular agricultural economy flow.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.full_name,
    u.phone,
    COUNT(DISTINCT p.product_id) AS products_listed_as_farmer,
    COUNT(DISTINCT o.order_id) AS orders_placed_as_buyer
FROM users u
JOIN products p ON u.user_id = p.farmer_id
JOIN orders o ON u.user_id = o.buyer_id
WHERE u.role = 'BOTH'
GROUP BY u.user_id, u.full_name, u.phone;
