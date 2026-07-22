-- ============================================================
-- Project: Production-Style E-Commerce Data Engineering Platform
-- File: 02_create_raw_tables.sql
-- Purpose: Create raw tables matching Olist CSV files
-- Layer: raw
-- ============================================================

-- Clean old raw tables if needed
DROP TABLE IF EXISTS raw.olist_customers_dataset CASCADE;
DROP TABLE IF EXISTS raw.olist_geolocation_dataset CASCADE;
DROP TABLE IF EXISTS raw.olist_order_items_dataset CASCADE;
DROP TABLE IF EXISTS raw.olist_order_payments_dataset CASCADE;
DROP TABLE IF EXISTS raw.olist_order_reviews_dataset CASCADE;
DROP TABLE IF EXISTS raw.olist_orders_dataset CASCADE;
DROP TABLE IF EXISTS raw.olist_products_dataset CASCADE;
DROP TABLE IF EXISTS raw.olist_sellers_dataset CASCADE;
DROP TABLE IF EXISTS raw.product_category_name_translation CASCADE;

-- 1. Customers raw table
CREATE TABLE raw.olist_customers_dataset (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

-- 2. Geolocation raw table
CREATE TABLE raw.olist_geolocation_dataset (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat TEXT,
    geolocation_lng TEXT,
    geolocation_city TEXT,
    geolocation_state TEXT
);

-- 3. Order items raw table
CREATE TABLE raw.olist_order_items_dataset (
    order_id TEXT,
    order_item_id TEXT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price TEXT,
    freight_value TEXT
);

-- 4. Order payments raw table
CREATE TABLE raw.olist_order_payments_dataset (
    order_id TEXT,
    payment_sequential TEXT,
    payment_type TEXT,
    payment_installments TEXT,
    payment_value TEXT
);

-- 5. Order reviews raw table
CREATE TABLE raw.olist_order_reviews_dataset (
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

-- 6. Orders raw table
CREATE TABLE raw.olist_orders_dataset (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

-- 7. Products raw table
CREATE TABLE raw.olist_products_dataset (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght TEXT,
    product_description_lenght TEXT,
    product_photos_qty TEXT,
    product_weight_g TEXT,
    product_length_cm TEXT,
    product_height_cm TEXT,
    product_width_cm TEXT
);

-- 8. Sellers raw table
CREATE TABLE raw.olist_sellers_dataset (
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

-- 9. Product category translation raw table
CREATE TABLE raw.product_category_name_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);