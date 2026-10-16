-- =====================================================================
-- 03_delivery_vs_reviews.sql
-- Do delivery performance and freight affect review scores? (Q4-Q6)
-- Tests H1 and H3.
-- Requires: 01_views.sql
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- Q4. Do late deliveries receive worse reviews?   (H1)
-- Result:  Early 4.29 | On Time 4.03 | Late 2.27   (~2-point gap)
-- ---------------------------------------------------------------------
SELECT
    oa.delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_review
FROM order_analysis oa
JOIN order_reviews r ON oa.order_id = r.order_id
WHERE oa.delivery_status IS NOT NULL
GROUP BY oa.delivery_status
ORDER BY avg_review DESC;


-- ---------------------------------------------------------------------
-- Q5. How strongly does delivery delay relate to review score?   (H1)
-- Result:
--   Early            4.29   (88,658 orders)
--   On-time          4.03   ( 1,291)
--   1-3 days late    3.29   ( 1,856)
--   4-7 days late    2.10   ( 1,756)
--   8-15 days late   1.68   ( 1,610)
--   15+ days late    1.73   ( 1,188)
-- Penalty is steepest in the first week, then plateaus.
-- ---------------------------------------------------------------------
SELECT
    CASE
        WHEN oa.delivery_delay_days < 0 THEN 'Early'
        WHEN oa.delivery_delay_days = 0 THEN 'On-time'
        WHEN oa.delivery_delay_days BETWEEN 1 AND 3 THEN '1-3 days delay'
        WHEN oa.delivery_delay_days BETWEEN 4 AND 7 THEN '4-7 days delay'
        WHEN oa.delivery_delay_days BETWEEN 8 AND 15 THEN '8-15 days delay'
        WHEN oa.delivery_delay_days > 15 THEN '15+ days delay'
    END AS delivery_bucket,
    ROUND(AVG(r.review_score), 2) AS avg_review,
    COUNT(oa.delivery_delay_days) AS num_orders
FROM order_analysis oa
JOIN order_reviews r ON oa.order_id = r.order_id
WHERE oa.delivery_delay_days IS NOT NULL
GROUP BY delivery_bucket
ORDER BY MIN(oa.delivery_delay_days) ASC;


-- ---------------------------------------------------------------------
-- Q6. Does freight burden affect reviews?   (H3)
-- freight_ratio = freight_value / price, computed per order item.
-- Result:  Low 4.07 | Medium 4.06 | High 4.03 | Very high 3.97
-- Only ~0.10 points across the whole range, vs ~2.0 for late delivery.
-- Bucket cutoffs (0.134 / 0.231 / 0.393) are hardcoded.
-- ---------------------------------------------------------------------
WITH freight_calc AS (
    SELECT
        oi.order_id,
        oi.freight_value / NULLIF(oi.price, 0) AS freight_ratio
    FROM order_items oi
)
SELECT
    CASE
        WHEN fc.freight_ratio < 0.134 THEN 'Low freight burden'
        WHEN fc.freight_ratio < 0.231 THEN 'Medium freight burden'
        WHEN fc.freight_ratio < 0.393 THEN 'High freight burden'
        ELSE 'Very high freight burden'
    END AS freight_burden,
    ROUND(AVG(r.review_score), 2) AS avg_review
FROM freight_calc fc
JOIN order_reviews r ON fc.order_id = r.order_id
GROUP BY freight_burden
ORDER BY avg_review DESC;
