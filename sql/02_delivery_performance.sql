-- =====================================================================
-- 02_delivery_performance.sql
-- How reliable is delivery? (Q1-Q3)
-- Requires: 01_views.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. What % of deliveries are early / on time / late?
-- Result:  Early 88,649 (91.89%) | On Time 1,292 (1.34%) | Late 6,535 (6.77%)
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
-- ---------------------------------------------------------------------
-- Q3. Which customer states have the highest late rates?
-- Top results: AL 21.41% | MA 17.43% | SE 15.22% | PI 13.87% | CE 13.76%
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
