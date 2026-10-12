create database marketplace;
use marketplace;

#Use at least 5 tables in meaningful joins.
WITH recommendation_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_impressions,
        SUM(CASE WHEN clicked = 1 THEN 1 ELSE 0 END) AS total_clicks
    FROM recommendations_impressions
    GROUP BY customer_id
),
event_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_events,
        SUM(
            CASE
                WHEN event_type IN ('add_to_cart', 'wishlist')
                THEN 1 ELSE 0
            END
        ) AS product_actions
    FROM customer_events
    GROUP BY customer_id
),
order_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(gmv) AS total_gmv,
        AVG(margin) AS avg_margin_rate
    FROM orders
    GROUP BY customer_id
),
ad_metrics AS (
    SELECT
        ae.customer_id,
        SUM(ae.impressions) AS ad_impressions,
        SUM(ae.clicks) AS ad_clicks,
        SUM(ae.spend) AS total_ad_spend,
        SUM(ae.ad_gmv) AS attributed_ad_gmv
    FROM ad_events ae
    INNER JOIN campaigns ca
        ON ae.campaign_id = ca.campaign_id
    GROUP BY ae.customer_id
)
SELECT
    c.customer_id,
    c.city,
    c.customer_segment,
    p.category,
    COALESCE(r.total_impressions, 0) AS recommendation_impressions,
    COALESCE(r.total_clicks, 0) AS recommendation_clicks,
    COALESCE(e.total_events, 0) AS total_events,
    COALESCE(e.product_actions, 0) AS product_actions,
    COALESCE(o.total_orders, 0) AS total_orders,
    COALESCE(o.total_gmv, 0) AS total_gmv,
    o.avg_margin_rate,
    COALESCE(a.ad_impressions, 0) AS ad_impressions,
    COALESCE(a.ad_clicks, 0) AS ad_clicks,
    a.total_ad_spend,
    a.attributed_ad_gmv
FROM customers c
LEFT JOIN recommendation_metrics r
    ON c.customer_id = r.customer_id
LEFT JOIN event_metrics e
    ON c.customer_id = e.customer_id
LEFT JOIN order_metrics o
    ON c.customer_id = o.customer_id
LEFT JOIN ad_metrics a
    ON c.customer_id = a.customer_id
LEFT JOIN recommendations_impressions ri
    ON c.customer_id = ri.customer_id
LEFT JOIN products p
    ON ri.product_id = p.product_id
GROUP BY
    c.customer_id,
    c.city,
    c.customer_segment,
    p.category,
    r.total_impressions,
    r.total_clicks,
    e.total_events,
    e.product_actions,
    o.total_orders,
    o.total_gmv,
    o.avg_margin_rate,
    a.ad_impressions,
    a.ad_clicks,
    a.total_ad_spend,
    a.attributed_ad_gmv; 