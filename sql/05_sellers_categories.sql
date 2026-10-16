-- =====================================================================
-- 05_sellers_categories.sql
-- Which sellers and categories need attention? (Q9-Q10)
-- Tests H4.
-- Requires: 01_views.sql
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- Context: the seller base is highly skewed (median 6 orders per seller,
-- mean ~32). Sellers with very large average delays (31 sellers average
-- > 10 days late) all have fewer than 10 orders. To avoid ranking tiny
-- sellers on noise, Q9 only considers sellers with 30+ delivered orders.
-- To reproduce the skew figures from the seller_analysis view:
--   SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY total_orders) AS median_orders,
--          ROUND(AVG(total_orders), 2) AS mean_orders,
--          COUNT(*) FILTER (WHERE avg_delay_days > 10) AS sellers_avg_delay_over_10d,
--          COUNT(*) FILTER (WHERE total_orders >= 10)  AS sellers_with_10plus_orders
--   FROM seller_analysis;
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- Q9. Which sellers need intervention?
-- Sellers with 30+ delivered orders, ranked by late-delivery rate.
-- The dashboard card shows the top 15 (add LIMIT 15 to reproduce it).
-- Worst: 32.56% late (43 orders, avg review 3.57); platform rate is 6.8%.
-- ---------------------------------------------------------------------
WITH seller_orders AS (
    SELECT DISTINCT seller_id, order_id
    FROM order_items
),
reviews_by_order AS (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    so.seller_id,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE oa.delivery_status = 'Late') AS late_orders,
    ROUND(
        COUNT(*) FILTER (WHERE oa.delivery_status = 'Late')::numeric
        / NULLIF(COUNT(*) FILTER (WHERE oa.delivery_status IS NOT NULL), 0) * 100,
        2) AS late_delivery_percentage,
    ROUND(AVG(r.review_score), 2) AS avg_seller_review,
    COUNT(*) FILTER (WHERE r.review_score IN (1, 2)) AS poor_review_orders
FROM seller_orders so
JOIN order_analysis oa ON so.order_id = oa.order_id
LEFT JOIN reviews_by_order r ON so.order_id = r.order_id
WHERE oa.order_status = 'delivered'
GROUP BY so.seller_id
HAVING COUNT(*) >= 30
ORDER BY late_delivery_percentage DESC, late_orders DESC;


-- ---------------------------------------------------------------------
-- Q10. Which categories have a customer-experience problem?
-- Categories with 100+ orders. Category names are in Portuguese as in the
-- source data (the dashboard shows English names via the dataset's
-- translation table). One group has a NULL category name (1,451 orders).
-- Key pattern: some categories have poor reviews despite fair delivery:
--   fashion_roupa_masculina  4.72% late, 26.13% poor reviews
--   moveis_escritorio        8.05% late, 22.80% poor reviews
--   telefonia_fixa           4.72% late, 18.69% poor reviews
--   audio                   11.78% late, 21.90% poor reviews  (delivery + product)
-- ---------------------------------------------------------------------
SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review,
    ROUND(
        COUNT(DISTINCT CASE WHEN oa.delivery_status = 'Late' THEN oi.order_id END)::numeric
        / NULLIF(COUNT(DISTINCT CASE WHEN oa.delivery_status IS NOT NULL THEN oi.order_id END), 0) * 100,
        2) AS late_delivery_pct,
    ROUND(
        COUNT(DISTINCT CASE WHEN r.review_score IN (1, 2) THEN oi.order_id END)::numeric
        / NULLIF(COUNT(DISTINCT CASE WHEN r.review_score IS NOT NULL THEN oi.order_id END), 0) * 100,
        2) AS poor_review_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN order_analysis oa ON oi.order_id = oa.order_id
LEFT JOIN order_reviews r ON oi.order_id = r.order_id
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) >= 100
ORDER BY avg_review ASC;
