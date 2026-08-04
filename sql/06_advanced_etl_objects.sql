-- ============================================================
-- Project: Production-Style E-Commerce Data Engineering Platform
-- File: 06_advanced_etl_objects.sql
-- Purpose: Advanced ETL objects for incremental load, hybrid join, and SCD Type 2
-- ============================================================

-- ============================================================
-- 1. Incremental ETL Control Table
-- ============================================================

CREATE TABLE IF NOT EXISTS audit.etl_control (
    pipeline_name VARCHAR(100) PRIMARY KEY,
    last_loaded_timestamp TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO audit.etl_control (
    pipeline_name,
    last_loaded_timestamp
)
VALUES (
    'incremental_orders_pipeline',
    '2018-01-01 00:00:00'
)
ON CONFLICT (pipeline_name)
DO NOTHING;

CREATE TABLE IF NOT EXISTS audit.incremental_load_log (
    log_id BIGSERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100),
    run_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_loaded_timestamp TIMESTAMP,
    new_max_timestamp TIMESTAMP,
    candidate_rows BIGINT,
    inserted_rows BIGINT,
    skipped_rows BIGINT,
    status VARCHAR(30),
    message TEXT
);

-- ============================================================
-- 2. Hybrid Join Enriched Table
-- ============================================================

DROP TABLE IF EXISTS warehouse.hybrid_join_enriched_order_items;

CREATE TABLE warehouse.hybrid_join_enriched_order_items (
    enriched_key BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(50),
    order_item_sequence INTEGER,
    product_id VARCHAR(50),
    product_category_name TEXT,
    product_category_name_english TEXT,
    seller_id VARCHAR(50),
    seller_city TEXT,
    seller_state VARCHAR(10),
    item_price NUMERIC(12,2),
    freight_value NUMERIC(12,2),
    total_item_cost NUMERIC(12,2),
    shipping_limit_date TIMESTAMP,
    enriched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. SCD Type 2 Product Dimension
-- ============================================================

DROP TABLE IF EXISTS warehouse.dim_product_scd2;

CREATE TABLE warehouse.dim_product_scd2 (
    product_scd_key BIGSERIAL PRIMARY KEY,
    product_id VARCHAR(50),
    product_category_name TEXT,
    product_category_name_english TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER,
    effective_start_date TIMESTAMP,
    effective_end_date TIMESTAMP,
    is_current BOOLEAN,
    record_hash TEXT
);

CREATE INDEX IF NOT EXISTS idx_dim_product_scd2_product_id
ON warehouse.dim_product_scd2(product_id);

CREATE INDEX IF NOT EXISTS idx_dim_product_scd2_current
ON warehouse.dim_product_scd2(product_id, is_current);