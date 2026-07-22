-- ============================================================
-- Project: Production-Style E-Commerce Data Engineering Platform
-- File: 05_create_warehouse_tables.sql
-- Purpose: Create and load warehouse star schema
-- Layer: warehouse
-- ============================================================

-- ============================================================
-- 1. Drop old warehouse tables
-- ============================================================

DROP TABLE IF EXISTS warehouse.fact_reviews CASCADE;
DROP TABLE IF EXISTS warehouse.fact_payments CASCADE;
DROP TABLE IF EXISTS warehouse.fact_order_items CASCADE;
DROP TABLE IF EXISTS warehouse.fact_orders CASCADE;

DROP TABLE IF EXISTS warehouse.dim_payment_type CASCADE;
DROP TABLE IF EXISTS warehouse.dim_geolocation CASCADE;
DROP TABLE IF EXISTS warehouse.dim_date CASCADE;
DROP TABLE IF EXISTS warehouse.dim_seller CASCADE;
DROP TABLE IF EXISTS warehouse.dim_product CASCADE;
DROP TABLE IF EXISTS warehouse.dim_customer CASCADE;

-- ============================================================
-- 2. Dimension Tables
-- ============================================================

CREATE TABLE warehouse.dim_customer (
    customer_key BIGSERIAL PRIMARY KEY,
    customer_id VARCHAR(50) UNIQUE,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state VARCHAR(10)
);

CREATE TABLE warehouse.dim_product (
    product_key BIGSERIAL PRIMARY KEY,
    product_id VARCHAR(50) UNIQUE,
    product_category_name TEXT,
    product_category_name_english TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

CREATE TABLE warehouse.dim_seller (
    seller_key BIGSERIAL PRIMARY KEY,
    seller_id VARCHAR(50) UNIQUE,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state VARCHAR(10)
);

CREATE TABLE warehouse.dim_payment_type (
    payment_type_key BIGSERIAL PRIMARY KEY,
    payment_type VARCHAR(50) UNIQUE
);

CREATE TABLE warehouse.dim_geolocation (
    geo_key BIGSERIAL PRIMARY KEY,
    zip_code_prefix INTEGER,
    city TEXT,
    state VARCHAR(10),
    avg_lat NUMERIC(12,8),
    avg_lng NUMERIC(12,8)
);

CREATE TABLE warehouse.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    day_of_month INTEGER,
    day_of_week INTEGER,
    week_of_year INTEGER,
    is_weekend BOOLEAN
);

-- ============================================================
-- 3. Fact Tables
-- ============================================================

CREATE TABLE warehouse.fact_orders (
    order_fact_key BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(50) UNIQUE,
    customer_key BIGINT REFERENCES warehouse.dim_customer(customer_key),
    purchase_date_key INTEGER REFERENCES warehouse.dim_date(date_key),
    approved_date_key INTEGER REFERENCES warehouse.dim_date(date_key),
    delivered_carrier_date_key INTEGER REFERENCES warehouse.dim_date(date_key),
    delivered_customer_date_key INTEGER REFERENCES warehouse.dim_date(date_key),
    estimated_delivery_date_key INTEGER REFERENCES warehouse.dim_date(date_key),
    order_status VARCHAR(30),
    delivery_days NUMERIC(10,2),
    delay_days NUMERIC(10,2),
    is_delivered_late BOOLEAN
);

CREATE TABLE warehouse.fact_order_items (
    order_item_fact_key BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES warehouse.fact_orders(order_id),
    order_item_sequence INTEGER,
    product_key BIGINT REFERENCES warehouse.dim_product(product_key),
    seller_key BIGINT REFERENCES warehouse.dim_seller(seller_key),
    shipping_limit_date_key INTEGER REFERENCES warehouse.dim_date(date_key),
    item_price NUMERIC(12,2),
    freight_value NUMERIC(12,2),
    total_item_cost NUMERIC(12,2)
);

CREATE TABLE warehouse.fact_payments (
    payment_fact_key BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(50) REFERENCES warehouse.fact_orders(order_id),
    payment_type_key BIGINT REFERENCES warehouse.dim_payment_type(payment_type_key),
    payment_sequential INTEGER,
    payment_installments INTEGER,
    payment_value NUMERIC(12,2)
);

CREATE TABLE warehouse.fact_reviews (
    review_fact_key BIGSERIAL PRIMARY KEY,
    review_id VARCHAR(50),
    order_id VARCHAR(50) REFERENCES warehouse.fact_orders(order_id),
    review_score INTEGER,
    review_creation_date_key INTEGER REFERENCES warehouse.dim_date(date_key),
    review_answer_date_key INTEGER REFERENCES warehouse.dim_date(date_key),
    response_time_hours NUMERIC(12,2),
    has_comment_title BOOLEAN,
    has_comment_message BOOLEAN
);

-- ============================================================
-- 4. Load Dimension Tables
-- ============================================================

INSERT INTO warehouse.dim_customer (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT DISTINCT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.customers
WHERE customer_id IS NOT NULL;

INSERT INTO warehouse.dim_product (
    product_id,
    product_category_name,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT DISTINCT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM staging.products p
LEFT JOIN staging.product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_id IS NOT NULL;

INSERT INTO warehouse.dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT DISTINCT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers
WHERE seller_id IS NOT NULL;

INSERT INTO warehouse.dim_payment_type (
    payment_type
)
SELECT DISTINCT
    payment_type
FROM staging.order_payments
WHERE payment_type IS NOT NULL;

INSERT INTO warehouse.dim_geolocation (
    zip_code_prefix,
    city,
    state,
    avg_lat,
    avg_lng
)
SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state,
    AVG(geolocation_lat) AS avg_lat,
    AVG(geolocation_lng) AS avg_lng
FROM staging.geolocation
WHERE geolocation_zip_code_prefix IS NOT NULL
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state;

-- ============================================================
-- 5. Load Date Dimension
-- ============================================================

WITH all_dates AS (
    SELECT order_purchase_timestamp::DATE AS full_date
    FROM staging.orders
    WHERE order_purchase_timestamp IS NOT NULL

    UNION

    SELECT order_approved_at::DATE
    FROM staging.orders
    WHERE order_approved_at IS NOT NULL

    UNION

    SELECT order_delivered_carrier_date::DATE
    FROM staging.orders
    WHERE order_delivered_carrier_date IS NOT NULL

    UNION

    SELECT order_delivered_customer_date::DATE
    FROM staging.orders
    WHERE order_delivered_customer_date IS NOT NULL

    UNION

    SELECT order_estimated_delivery_date::DATE
    FROM staging.orders
    WHERE order_estimated_delivery_date IS NOT NULL

    UNION

    SELECT shipping_limit_date::DATE
    FROM staging.order_items
    WHERE shipping_limit_date IS NOT NULL

    UNION

    SELECT review_creation_date::DATE
    FROM staging.order_reviews
    WHERE review_creation_date IS NOT NULL

    UNION

    SELECT review_answer_timestamp::DATE
    FROM staging.order_reviews
    WHERE review_answer_timestamp IS NOT NULL
)
INSERT INTO warehouse.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day_of_month,
    day_of_week,
    week_of_year,
    is_weekend
)
SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::INTEGER AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date)::INTEGER AS year,
    EXTRACT(QUARTER FROM full_date)::INTEGER AS quarter,
    EXTRACT(MONTH FROM full_date)::INTEGER AS month,
    TO_CHAR(full_date, 'Month') AS month_name,
    EXTRACT(DAY FROM full_date)::INTEGER AS day_of_month,
    EXTRACT(ISODOW FROM full_date)::INTEGER AS day_of_week,
    EXTRACT(WEEK FROM full_date)::INTEGER AS week_of_year,
    CASE
        WHEN EXTRACT(ISODOW FROM full_date) IN (6, 7) THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM all_dates
WHERE full_date IS NOT NULL
ORDER BY full_date;

-- ============================================================
-- 6. Load Fact Orders
-- ============================================================

INSERT INTO warehouse.fact_orders (
    order_id,
    customer_key,
    purchase_date_key,
    approved_date_key,
    delivered_carrier_date_key,
    delivered_customer_date_key,
    estimated_delivery_date_key,
    order_status,
    delivery_days,
    delay_days,
    is_delivered_late
)
SELECT
    o.order_id,
    dc.customer_key,
    dp.date_key AS purchase_date_key,
    da.date_key AS approved_date_key,
    dcarrier.date_key AS delivered_carrier_date_key,
    dcustomer.date_key AS delivered_customer_date_key,
    dest.date_key AS estimated_delivery_date_key,
    o.order_status,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_purchase_timestamp IS NOT NULL
        THEN ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0, 2)
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0, 2)
        ELSE NULL
    END AS delay_days,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN TRUE
        ELSE FALSE
    END AS is_delivered_late

FROM staging.orders o
LEFT JOIN warehouse.dim_customer dc
    ON o.customer_id = dc.customer_id
LEFT JOIN warehouse.dim_date dp
    ON o.order_purchase_timestamp::DATE = dp.full_date
LEFT JOIN warehouse.dim_date da
    ON o.order_approved_at::DATE = da.full_date
LEFT JOIN warehouse.dim_date dcarrier
    ON o.order_delivered_carrier_date::DATE = dcarrier.full_date
LEFT JOIN warehouse.dim_date dcustomer
    ON o.order_delivered_customer_date::DATE = dcustomer.full_date
LEFT JOIN warehouse.dim_date dest
    ON o.order_estimated_delivery_date::DATE = dest.full_date
WHERE o.order_id IS NOT NULL;

-- ============================================================
-- 7. Load Fact Order Items
-- ============================================================

INSERT INTO warehouse.fact_order_items (
    order_id,
    order_item_sequence,
    product_key,
    seller_key,
    shipping_limit_date_key,
    item_price,
    freight_value,
    total_item_cost
)
SELECT
    oi.order_id,
    oi.order_item_id,
    dp.product_key,
    ds.seller_key,
    dd.date_key AS shipping_limit_date_key,
    oi.price,
    oi.freight_value,
    COALESCE(oi.price, 0) + COALESCE(oi.freight_value, 0) AS total_item_cost
FROM staging.order_items oi
JOIN warehouse.fact_orders fo
    ON oi.order_id = fo.order_id
LEFT JOIN warehouse.dim_product dp
    ON oi.product_id = dp.product_id
LEFT JOIN warehouse.dim_seller ds
    ON oi.seller_id = ds.seller_id
LEFT JOIN warehouse.dim_date dd
    ON oi.shipping_limit_date::DATE = dd.full_date;

-- ============================================================
-- 8. Load Fact Payments
-- ============================================================

INSERT INTO warehouse.fact_payments (
    order_id,
    payment_type_key,
    payment_sequential,
    payment_installments,
    payment_value
)
SELECT
    op.order_id,
    dpt.payment_type_key,
    op.payment_sequential,
    op.payment_installments,
    op.payment_value
FROM staging.order_payments op
JOIN warehouse.fact_orders fo
    ON op.order_id = fo.order_id
LEFT JOIN warehouse.dim_payment_type dpt
    ON op.payment_type = dpt.payment_type;

-- ============================================================
-- 9. Load Fact Reviews
-- ============================================================

INSERT INTO warehouse.fact_reviews (
    review_id,
    order_id,
    review_score,
    review_creation_date_key,
    review_answer_date_key,
    response_time_hours,
    has_comment_title,
    has_comment_message
)
SELECT
    r.review_id,
    r.order_id,
    r.review_score,
    dcreate.date_key AS review_creation_date_key,
    danswer.date_key AS review_answer_date_key,

    CASE
        WHEN r.review_creation_date IS NOT NULL
         AND r.review_answer_timestamp IS NOT NULL
        THEN ROUND(EXTRACT(EPOCH FROM (r.review_answer_timestamp - r.review_creation_date)) / 3600.0, 2)
        ELSE NULL
    END AS response_time_hours,

    CASE
        WHEN r.review_comment_title IS NOT NULL
         AND LENGTH(TRIM(r.review_comment_title)) > 0
        THEN TRUE
        ELSE FALSE
    END AS has_comment_title,

    CASE
        WHEN r.review_comment_message IS NOT NULL
         AND LENGTH(TRIM(r.review_comment_message)) > 0
        THEN TRUE
        ELSE FALSE
    END AS has_comment_message

FROM staging.order_reviews r
JOIN warehouse.fact_orders fo
    ON r.order_id = fo.order_id
LEFT JOIN warehouse.dim_date dcreate
    ON r.review_creation_date::DATE = dcreate.full_date
LEFT JOIN warehouse.dim_date danswer
    ON r.review_answer_timestamp::DATE = danswer.full_date;