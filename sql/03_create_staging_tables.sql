-- ============================================================
-- Project: Production-Style E-Commerce Data Engineering Platform
-- File: 03_create_staging_tables.sql
-- Purpose: Create and load typed staging tables from raw tables
-- Layer: staging
-- ============================================================

DROP TABLE IF EXISTS staging.customers CASCADE;
DROP TABLE IF EXISTS staging.geolocation CASCADE;
DROP TABLE IF EXISTS staging.order_items CASCADE;
DROP TABLE IF EXISTS staging.order_payments CASCADE;
DROP TABLE IF EXISTS staging.order_reviews CASCADE;
DROP TABLE IF EXISTS staging.orders CASCADE;
DROP TABLE IF EXISTS staging.products CASCADE;
DROP TABLE IF EXISTS staging.sellers CASCADE;
DROP TABLE IF EXISTS staging.product_category_translation CASCADE;

-- ============================================================
-- 1. Customers
-- ============================================================

CREATE TABLE staging.customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state VARCHAR(10)
);

INSERT INTO staging.customers
SELECT
    NULLIF(TRIM(customer_id), '') AS customer_id,
    NULLIF(TRIM(customer_unique_id), '') AS customer_unique_id,
    NULLIF(TRIM(customer_zip_code_prefix), '')::INTEGER AS customer_zip_code_prefix,
    LOWER(NULLIF(TRIM(customer_city), '')) AS customer_city,
    NULLIF(TRIM(customer_state), '') AS customer_state
FROM raw.olist_customers_dataset;

-- ============================================================
-- 2. Geolocation
-- ============================================================

CREATE TABLE staging.geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat NUMERIC(12,8),
    geolocation_lng NUMERIC(12,8),
    geolocation_city TEXT,
    geolocation_state VARCHAR(10)
);

INSERT INTO staging.geolocation
SELECT
    NULLIF(TRIM(geolocation_zip_code_prefix), '')::INTEGER,
    NULLIF(TRIM(geolocation_lat), '')::NUMERIC(12,8),
    NULLIF(TRIM(geolocation_lng), '')::NUMERIC(12,8),
    LOWER(NULLIF(TRIM(geolocation_city), '')),
    NULLIF(TRIM(geolocation_state), '')
FROM raw.olist_geolocation_dataset;

-- ============================================================
-- 3. Order Items
-- ============================================================

CREATE TABLE staging.order_items (
    order_id VARCHAR(50),
    order_item_id INTEGER,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2)
);

INSERT INTO staging.order_items
SELECT
    NULLIF(TRIM(order_id), ''),
    NULLIF(TRIM(order_item_id), '')::INTEGER,
    NULLIF(TRIM(product_id), ''),
    NULLIF(TRIM(seller_id), ''),
    NULLIF(TRIM(shipping_limit_date), '')::TIMESTAMP,
    NULLIF(TRIM(price), '')::NUMERIC(12,2),
    NULLIF(TRIM(freight_value), '')::NUMERIC(12,2)
FROM raw.olist_order_items_dataset;

-- ============================================================
-- 4. Order Payments
-- ============================================================

CREATE TABLE staging.order_payments (
    order_id VARCHAR(50),
    payment_sequential INTEGER,
    payment_type VARCHAR(50),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2)
);

INSERT INTO staging.order_payments
SELECT
    NULLIF(TRIM(order_id), ''),
    NULLIF(TRIM(payment_sequential), '')::INTEGER,
    NULLIF(TRIM(payment_type), ''),
    NULLIF(TRIM(payment_installments), '')::INTEGER,
    NULLIF(TRIM(payment_value), '')::NUMERIC(12,2)
FROM raw.olist_order_payments_dataset;

-- ============================================================
-- 5. Order Reviews
-- ============================================================

CREATE TABLE staging.order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

INSERT INTO staging.order_reviews
SELECT
    NULLIF(TRIM(review_id), ''),
    NULLIF(TRIM(order_id), ''),
    NULLIF(TRIM(review_score), '')::INTEGER,
    NULLIF(TRIM(review_comment_title), ''),
    NULLIF(TRIM(review_comment_message), ''),
    NULLIF(TRIM(review_creation_date), '')::TIMESTAMP,
    NULLIF(TRIM(review_answer_timestamp), '')::TIMESTAMP
FROM raw.olist_order_reviews_dataset;

-- ============================================================
-- 6. Orders
-- ============================================================

CREATE TABLE staging.orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

INSERT INTO staging.orders
SELECT
    NULLIF(TRIM(order_id), ''),
    NULLIF(TRIM(customer_id), ''),
    NULLIF(TRIM(order_status), ''),
    NULLIF(TRIM(order_purchase_timestamp), '')::TIMESTAMP,
    NULLIF(TRIM(order_approved_at), '')::TIMESTAMP,
    NULLIF(TRIM(order_delivered_carrier_date), '')::TIMESTAMP,
    NULLIF(TRIM(order_delivered_customer_date), '')::TIMESTAMP,
    NULLIF(TRIM(order_estimated_delivery_date), '')::TIMESTAMP
FROM raw.olist_orders_dataset;

-- ============================================================
-- 7. Products
-- Note: Olist dataset spelling is "lenght", not "length"
-- ============================================================

CREATE TABLE staging.products (
    product_id VARCHAR(50),
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

INSERT INTO staging.products
SELECT
    NULLIF(TRIM(product_id), ''),
    NULLIF(TRIM(product_category_name), ''),
    NULLIF(TRIM(product_name_lenght), '')::INTEGER,
    NULLIF(TRIM(product_description_lenght), '')::INTEGER,
    NULLIF(TRIM(product_photos_qty), '')::INTEGER,
    NULLIF(TRIM(product_weight_g), '')::INTEGER,
    NULLIF(TRIM(product_length_cm), '')::INTEGER,
    NULLIF(TRIM(product_height_cm), '')::INTEGER,
    NULLIF(TRIM(product_width_cm), '')::INTEGER
FROM raw.olist_products_dataset;

-- ============================================================
-- 8. Sellers
-- ============================================================

CREATE TABLE staging.sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state VARCHAR(10)
);

INSERT INTO staging.sellers
SELECT
    NULLIF(TRIM(seller_id), ''),
    NULLIF(TRIM(seller_zip_code_prefix), '')::INTEGER,
    LOWER(NULLIF(TRIM(seller_city), '')),
    NULLIF(TRIM(seller_state), '')
FROM raw.olist_sellers_dataset;

-- ============================================================
-- 9. Product Category Translation
-- ============================================================

CREATE TABLE staging.product_category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);

INSERT INTO staging.product_category_translation
SELECT
    NULLIF(TRIM(product_category_name), ''),
    NULLIF(TRIM(product_category_name_english), '')
FROM raw.product_category_name_translation;