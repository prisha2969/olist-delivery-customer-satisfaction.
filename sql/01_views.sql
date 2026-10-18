-- =====================================================================
-- 01_views.sql
-- Analysis views used by all later queries (PostgreSQL).
-- Source tables: orders, customers, order_items, order_reviews,
--                sellers, products (Olist Brazilian E-Commerce dataset)
-- =====================================================================
-- order_analysis: one row per order with delivery metrics.
--   delivery_lead_time_days = delivered date - purchase date
--   delivery_delay_days     = delivered date - estimated date
--                             (negative = early, 0 = on time, >0 = late)
-- Notes:
--   * "On Time" means delivered
--     on the same calendar day as the estimate.
--   * delivery_status is NULL when the delivered or estimated date is
--     missing (e.g. undelivered / cancelled orders).
--   * NOT filtered by order_status; downstream queries add the filter.
-- ---------------------------------------------------------------------
CREATE VIEW order_analysis AS
SELECT order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    order_delivered_customer_date::date - order_purchase_timestamp::date   AS delivery_lead_time_days,
    order_delivered_customer_date::date - order_estimated_delivery_date::date AS delivery_delay_days,
    CASE
        WHEN order_delivered_customer_date IS NULL
          OR order_estimated_delivery_date IS NULL THEN NULL::text
        WHEN (order_delivered_customer_date::date - order_estimated_delivery_date::date) < 0 THEN 'Early'::text
        WHEN (order_delivered_customer_date::date - order_estimated_delivery_date::date) = 0 THEN 'On Time'::text
        ELSE 'Late'::text
    END AS delivery_status
FROM orders;

-- ---------------------------------------------------------------------
-- customer_analysis: one row per REAL PERSON (customer_unique_id),
-- delivered orders only.
--   * customer_id is generated per order, so it cannot identify repeat
--     buyers. customer_unique_id is the person-level identifier.
--   * Grouped by customer_unique_id ONLY. An earlier version also grouped
--     by city, which split customers who moved into several rows and
--     slightly understated the repeat rate (2.89% -> 3.00% once fixed).
--   * customer_state = the person's most frequent state.
-- ---------------------------------------------------------------------
CREATE VIEW customer_analysis AS
SELECT c.customer_unique_id,
    MODE() WITHIN GROUP (ORDER BY c.customer_state) AS customer_state,
    COUNT(DISTINCT o.order_id) AS total_order,
    CASE
        WHEN COUNT(DISTINCT o.order_id) > 1 THEN 'repeat customer'
        ELSE 'one-time customer'
    END AS customer_type
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;

-- ---------------------------------------------------------------------
-- seller_analysis: one row per seller.
-- Note: includes non-delivered orders in the denominator and in revenue.
-- The seller-intervention query (05) applies its own delivered filter.
-- ---------------------------------------------------------------------
CREATE VIEW seller_analysis AS
WITH seller_order AS (
    SELECT DISTINCT i.seller_id, o.order_id, o.delivery_delay_days, o.delivery_status
    FROM order_items i
    JOIN order_analysis o ON i.order_id = o.order_id
),
seller_revenue AS (
    SELECT seller_id, SUM(price) AS total_revenue
    FROM order_items
    GROUP BY seller_id
)
SELECT s.seller_id,
    s.seller_state,
    COUNT(so.order_id) AS total_orders,
    ROUND(AVG(so.delivery_delay_days), 2) AS avg_delay_days,
    ROUND(COUNT(*) FILTER (WHERE so.delivery_status = 'Late')::numeric
          / COUNT(*) * 100, 2) AS late_percent,
    sr.total_revenue
FROM sellers s
JOIN seller_order so ON s.seller_id = so.seller_id
JOIN seller_revenue sr ON s.seller_id = sr.seller_id
GROUP BY s.seller_id, s.seller_state, sr.total_revenue;
