-- =====================================================================
-- 02_delivery_performance.sql
-- How reliable is delivery? (Q1-Q3)
-- Requires: 01_views.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. What % of deliveries are early / on time / late?
-- Result:  Early 88,649 (91.89%) | On Time 1,292 (1.34%) | Late 6,535 (6.77%)
-- Note: not filtered by order_status, so the base is 96,476. The dashboard
-- KPI (96,470 delivered orders) filters to delivered orders.
-- ---------------------------------------------------------------------
SELECT
    delivery_status,
    COUNT(delivery_status) AS count_status,
    ROUND(
        COUNT(delivery_status)::numeric /
        (SELECT COUNT(*) FROM order_analysis WHERE delivery_status IS NOT NULL) * 100,
        2) AS percent_status
FROM order_analysis
WHERE delivery_status IS NOT NULL
GROUP BY delivery_status;


-- ---------------------------------------------------------------------
-- Q2. How long does delivery actually take?
-- Dashboard KPI: average lead time = 12.41 days
-- ---------------------------------------------------------------------
SELECT
    AVG(delivery_lead_time_days) AS avg_time_taken,
    MIN(delivery_lead_time_days) AS fastest_delivery,
    MAX(delivery_lead_time_days) AS slowest_delivery
FROM order_analysis;

-- Data check: inspect extreme lead times (> 60 days)
SELECT
    oa.order_id,
    oa.order_status,
    oa.order_purchase_timestamp,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oa.delivery_lead_time_days,
    oa.delivery_delay_days
FROM order_analysis oa
JOIN orders o ON oa.order_id = o.order_id
WHERE oa.delivery_lead_time_days > 60
ORDER BY oa.delivery_lead_time_days DESC
LIMIT 20;

-- Data check: share of delivered orders taking > 60 days
SELECT
    COUNT(delivery_lead_time_days) AS extreme_orders,
    ROUND(COUNT(delivery_lead_time_days)::numeric /
          (SELECT COUNT(*) FROM order_analysis WHERE order_status = 'delivered') * 100,
          2) AS extreme_percentage
FROM order_analysis
WHERE delivery_lead_time_days > 60
  AND order_status = 'delivered';


-- ---------------------------------------------------------------------
-- Q3. Which customer states have the highest late rates?
-- Top results: AL 21.41% | MA 17.43% | SE 15.22% | PI 13.87% | CE 13.76%
-- Large states for comparison: SP 4.49% | MG 4.57% | RJ 12.11%
-- The dashboard chart shows slightly different values (e.g. AL 20.84%),
-- as that card is built from a separately configured Metabase query.
-- ---------------------------------------------------------------------
SELECT
    c.customer_state,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE oa.delivery_status = 'Late') AS late_orders,
    ROUND(
        COUNT(*) FILTER (WHERE oa.delivery_status = 'Late')::numeric
        / NULLIF(COUNT(*), 0) * 100,
        2) AS late_percent
FROM customers c
JOIN order_analysis oa ON c.customer_id = oa.customer_id
WHERE oa.order_status = 'delivered'
  AND oa.delivery_status IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_percent DESC;
