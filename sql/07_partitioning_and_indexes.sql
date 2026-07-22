-- ============================================================
-- Project: Production-Style E-Commerce Data Engineering Platform
-- File: 07_partitioning_and_indexes.sql
-- Purpose: Partitioning, indexing, and query optimization objects
-- Layer: warehouse
-- ============================================================

-- ============================================================
-- 1. Drop old partitioned table if exists
-- ============================================================

DROP TABLE IF EXISTS warehouse.fact_orders_partitioned CASCADE;

-- ============================================================
-- 2. Create partitioned fact orders table
-- Partition key: purchase_date
-- ============================================================

CREATE TABLE warehouse.fact_orders_partitioned (
    order_fact_key BIGINT,
    order_id VARCHAR(50),
    customer_key BIGINT,
    purchase_date DATE,
    purchase_year INTEGER,
    purchase_month INTEGER,
    order_status VARCHAR(30),
    delivery_days NUMERIC(10,2),
    delay_days NUMERIC(10,2),
    is_delivered_late BOOLEAN
)
PARTITION BY RANGE (purchase_date);

-- ============================================================
-- 3. Create yearly partitions
-- ============================================================

CREATE TABLE warehouse.fact_orders_2016
PARTITION OF warehouse.fact_orders_partitioned
FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE warehouse.fact_orders_2017
PARTITION OF warehouse.fact_orders_partitioned
FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

CREATE TABLE warehouse.fact_orders_2018
PARTITION OF warehouse.fact_orders_partitioned
FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');

CREATE TABLE warehouse.fact_orders_2019
PARTITION OF warehouse.fact_orders_partitioned
FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');

-- ============================================================
-- 4. Load data into partitioned table
-- ============================================================

INSERT INTO warehouse.fact_orders_partitioned (
    order_fact_key,
    order_id,
    customer_key,
    purchase_date,
    purchase_year,
    purchase_month,
    order_status,
    delivery_days,
    delay_days,
    is_delivered_late
)
SELECT
    fo.order_fact_key,
    fo.order_id,
    fo.customer_key,
    dd.full_date AS purchase_date,
    dd.year AS purchase_year,
    dd.month AS purchase_month,
    fo.order_status,
    fo.delivery_days,
    fo.delay_days,
    fo.is_delivered_late
FROM warehouse.fact_orders fo
JOIN warehouse.dim_date dd
    ON fo.purchase_date_key = dd.date_key
WHERE dd.full_date >= '2016-01-01'
  AND dd.full_date < '2020-01-01';

-- ============================================================
-- 5. Indexes on warehouse fact tables
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_orders_customer_key
ON warehouse.fact_orders(customer_key);

CREATE INDEX IF NOT EXISTS idx_fact_orders_purchase_date_key
ON warehouse.fact_orders(purchase_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_orders_status
ON warehouse.fact_orders(order_status);

CREATE INDEX IF NOT EXISTS idx_fact_order_items_order_id
ON warehouse.fact_order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_fact_order_items_product_key
ON warehouse.fact_order_items(product_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_items_seller_key
ON warehouse.fact_order_items(seller_key);

CREATE INDEX IF NOT EXISTS idx_fact_payments_order_id
ON warehouse.fact_payments(order_id);

CREATE INDEX IF NOT EXISTS idx_fact_payments_payment_type_key
ON warehouse.fact_payments(payment_type_key);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_order_id
ON warehouse.fact_reviews(order_id);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_review_score
ON warehouse.fact_reviews(review_score);

-- ============================================================
-- 6. Indexes on dimension tables
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_dim_customer_city_state
ON warehouse.dim_customer(customer_city, customer_state);

CREATE INDEX IF NOT EXISTS idx_dim_product_category
ON warehouse.dim_product(product_category_name_english);

CREATE INDEX IF NOT EXISTS idx_dim_seller_city_state
ON warehouse.dim_seller(seller_city, seller_state);

CREATE INDEX IF NOT EXISTS idx_dim_date_year_month
ON warehouse.dim_date(year, month);

-- ============================================================
-- 7. Indexes on partitioned table
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fact_orders_partitioned_purchase_date
ON warehouse.fact_orders_partitioned(purchase_date);

CREATE INDEX IF NOT EXISTS idx_fact_orders_partitioned_status
ON warehouse.fact_orders_partitioned(order_status);

CREATE INDEX IF NOT EXISTS idx_fact_orders_partitioned_year_month
ON warehouse.fact_orders_partitioned(purchase_year, purchase_month);

-- ============================================================
-- 8. Update PostgreSQL statistics
-- ============================================================

ANALYZE warehouse.fact_orders;
ANALYZE warehouse.fact_order_items;
ANALYZE warehouse.fact_payments;
ANALYZE warehouse.fact_reviews;
ANALYZE warehouse.dim_customer;
ANALYZE warehouse.dim_product;
ANALYZE warehouse.dim_seller;
ANALYZE warehouse.dim_date;
ANALYZE warehouse.fact_orders_partitioned;