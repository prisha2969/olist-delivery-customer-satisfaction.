-- =====================================================================
-- 04_repeat_purchase.sql
-- Who comes back, and does first-order experience explain it? (Q7-Q8)
-- Tests H2 and H5.
-- Requires: 01_views.sql
--
-- Reminder: customer_id is per ORDER; customer_unique_id is per PERSON.
-- All repeat-behaviour analysis uses customer_unique_id.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- Q7. How many customers are repeat customers?
-- Result:  repeat customer 2,801 (3.00%) | one-time customer 90,557 (97.00%)
-- ---------------------------------------------------------------------
SELECT
    customer_type,
    COUNT(*) AS no_of_customers,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_customers
FROM customer_analysis
GROUP BY customer_type;


-- ---------------------------------------------------------------------
-- Q8. Does the FIRST order differ between repeat and one-time customers?
--     (H2, H5)
-- Result:
--   customer_type       customers  avg_first_review  avg_first_delay  first_order_late_%
--   one-time customer     90,557        4.15             -11.83             6.84
--   repeat customer        2,801        4.20             -12.70             5.71
-- Reading: first-order review scores are almost identical (H2 not
-- supported). Repeat customers' first orders were slightly less often late.
-- ---------------------------------------------------------------------
WITH ranked_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        oa.delivery_delay_days,
        oa.delivery_status,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp, o.order_id
        ) AS order_number
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_analysis oa ON o.order_id = oa.order_id
    WHERE o.order_status = 'delivered'
),
first_orders AS (
    SELECT * FROM ranked_orders WHERE order_number = 1
),
reviews_by_order AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    ca.customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(r.review_score), 2) AS avg_first_review,
    ROUND(AVG(fo.delivery_delay_days), 2) AS avg_first_delay,
    ROUND(
        SUM(CASE WHEN fo.delivery_status = 'Late' THEN 1 ELSE 0 END)::numeric
        / NULLIF(COUNT(fo.delivery_status), 0) * 100,
        2) AS first_order_late_percent
FROM first_orders fo
JOIN customer_analysis ca ON fo.customer_unique_id = ca.customer_unique_id
LEFT JOIN reviews_by_order r ON fo.order_id = r.order_id
GROUP BY ca.customer_type
ORDER BY ca.customer_type;
