-- ============================================================
-- Project: Production-Style E-Commerce Data Engineering Platform
-- File: 08_create_mart_views.sql
-- Purpose: Create dashboard-ready analytical mart views
-- Layer: mart
-- ============================================================

-- ============================================================
-- 1. Monthly Revenue View
-- ============================================================

CREATE OR REPLACE VIEW mart.monthly_revenue_view AS
SELECT
    dd.year,
    dd.month,
    TRIM(dd.month_name) AS month_name,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    ROUND(SUM(foi.item_price), 2) AS total_item_revenue,
    ROUND(SUM(foi.freight_value), 2) AS total_freight_revenue,
    ROUND(SUM(foi.total_item_cost), 2) AS total_customer_cost,
    ROUND(AVG(foi.total_item_cost), 2) AS avg_item_cost
FROM warehouse.fact_orders fo
JOIN warehouse.fact_order_items foi
    ON fo.order_id = foi.order_id
JOIN warehouse.dim_date dd
    ON fo.purchase_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name
ORDER BY
    dd.year,
    dd.month;

-- ============================================================
-- 2. Top Products View
-- ============================================================

CREATE OR REPLACE VIEW mart.top_products_view AS
SELECT
    dp.product_category_name_english,
    COUNT(DISTINCT foi.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(foi.item_price), 2) AS total_revenue,
    ROUND(AVG(foi.item_price), 2) AS avg_item_price
FROM warehouse.fact_order_items foi
JOIN warehouse.dim_product dp
    ON foi.product_key = dp.product_key
GROUP BY
    dp.product_category_name_english
ORDER BY
    total_revenue DESC;

-- ============================================================
-- 3. Seller Performance View
-- ============================================================

CREATE OR REPLACE VIEW mart.seller_performance_view AS
SELECT
    ds.seller_id,
    ds.seller_city,
    ds.seller_state,
    COUNT(DISTINCT foi.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(foi.item_price), 2) AS total_revenue,
    ROUND(AVG(foi.item_price), 2) AS avg_item_price
FROM warehouse.fact_order_items foi
JOIN warehouse.dim_seller ds
    ON foi.seller_key = ds.seller_key
GROUP BY
    ds.seller_id,
    ds.seller_city,
    ds.seller_state
ORDER BY
    total_revenue DESC;

-- ============================================================
-- 4. Delivery Delay View
-- ============================================================

CREATE OR REPLACE VIEW mart.delivery_delay_view AS
SELECT
    fo.order_status,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE fo.is_delivered_late = TRUE) AS late_orders,
    COUNT(*) FILTER (WHERE fo.is_delivered_late = FALSE) AS on_time_or_not_late_orders,
    ROUND(AVG(fo.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(fo.delay_days), 2) AS avg_delay_days
FROM warehouse.fact_orders fo
GROUP BY
    fo.order_status
ORDER BY
    total_orders DESC;

-- ============================================================
-- 5. Payment Method Analysis View
-- ============================================================

CREATE OR REPLACE VIEW mart.payment_method_analysis_view AS
SELECT
    dpt.payment_type,
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT fp.order_id) AS total_orders,
    ROUND(SUM(fp.payment_value), 2) AS total_payment_value,
    ROUND(AVG(fp.payment_value), 2) AS avg_payment_value,
    ROUND(AVG(fp.payment_installments), 2) AS avg_installments
FROM warehouse.fact_payments fp
JOIN warehouse.dim_payment_type dpt
    ON fp.payment_type_key = dpt.payment_type_key
GROUP BY
    dpt.payment_type
ORDER BY
    total_payment_value DESC;

-- ============================================================
-- 6. Review Score Trend View
-- ============================================================

CREATE OR REPLACE VIEW mart.review_score_trend_view AS
SELECT
    dd.year,
    dd.month,
    TRIM(dd.month_name) AS month_name,
    fr.review_score,
    COUNT(*) AS total_reviews,
    ROUND(AVG(fr.response_time_hours), 2) AS avg_response_time_hours
FROM warehouse.fact_reviews fr
JOIN warehouse.dim_date dd
    ON fr.review_creation_date_key = dd.date_key
GROUP BY
    dd.year,
    dd.month,
    dd.month_name,
    fr.review_score
ORDER BY
    dd.year,
    dd.month,
    fr.review_score;

-- ============================================================
-- 7. Customer Location Sales View
-- ============================================================

CREATE OR REPLACE VIEW mart.customer_location_sales_view AS
SELECT
    dc.customer_city,
    dc.customer_state,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    COUNT(DISTINCT dc.customer_unique_id) AS unique_customers,
    ROUND(SUM(foi.total_item_cost), 2) AS total_customer_cost
FROM warehouse.fact_orders fo
JOIN warehouse.dim_customer dc
    ON fo.customer_key = dc.customer_key
JOIN warehouse.fact_order_items foi
    ON fo.order_id = foi.order_id
GROUP BY
    dc.customer_city,
    dc.customer_state
ORDER BY
    total_customer_cost DESC;