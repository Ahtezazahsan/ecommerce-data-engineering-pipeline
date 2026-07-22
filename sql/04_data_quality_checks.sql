-- ============================================================
-- Project: Production-Style E-Commerce Data Engineering Platform
-- File: 04_data_quality_checks.sql
-- Purpose: Create audit tables and run data quality checks
-- Layer: audit
-- ============================================================

-- ============================================================
-- 1. Audit Tables
-- ============================================================

CREATE TABLE IF NOT EXISTS audit.etl_run_log (
    run_id BIGSERIAL PRIMARY KEY,
    pipeline_name VARCHAR(100),
    run_step VARCHAR(100),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    status VARCHAR(30),
    rows_checked BIGINT DEFAULT 0,
    rows_rejected BIGINT DEFAULT 0,
    message TEXT
);

CREATE TABLE IF NOT EXISTS audit.data_quality_log (
    check_id BIGSERIAL PRIMARY KEY,
    check_name VARCHAR(150),
    table_name VARCHAR(100),
    check_type VARCHAR(80),
    issue_count BIGINT,
    severity VARCHAR(20),
    check_status VARCHAR(30),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit.etl_reject_records (
    reject_id BIGSERIAL PRIMARY KEY,
    source_table VARCHAR(100),
    record_key TEXT,
    rule_name VARCHAR(150),
    error_description TEXT,
    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clean previous quality run results
TRUNCATE TABLE audit.data_quality_log;
TRUNCATE TABLE audit.etl_reject_records;

-- ============================================================
-- 2. Start ETL Quality Run Log
-- ============================================================

INSERT INTO audit.etl_run_log (
    pipeline_name,
    run_step,
    status,
    message
)
VALUES (
    'olist_ecommerce_pipeline',
    'data_quality_checks',
    'RUNNING',
    'Data quality validation started for staging layer.'
);

-- ============================================================
-- 3. Null Key Checks
-- ============================================================

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'customers_customer_id_null',
    'staging.customers',
    'NULL_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.customers
WHERE customer_id IS NULL;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'orders_order_id_null',
    'staging.orders',
    'NULL_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.orders
WHERE order_id IS NULL;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'products_product_id_null',
    'staging.products',
    'NULL_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.products
WHERE product_id IS NULL;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'sellers_seller_id_null',
    'staging.sellers',
    'NULL_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.sellers
WHERE seller_id IS NULL;

-- ============================================================
-- 4. Duplicate Business Key Checks
-- ============================================================

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'duplicate_customer_id',
    'staging.customers',
    'DUPLICATE_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM (
    SELECT customer_id
    FROM staging.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) d;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'duplicate_order_id',
    'staging.orders',
    'DUPLICATE_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM (
    SELECT order_id
    FROM staging.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) d;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'duplicate_product_id',
    'staging.products',
    'DUPLICATE_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM (
    SELECT product_id
    FROM staging.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) d;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'duplicate_seller_id',
    'staging.sellers',
    'DUPLICATE_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM (
    SELECT seller_id
    FROM staging.sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) d;

-- ============================================================
-- 5. Negative Numeric Value Checks
-- ============================================================

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'negative_order_item_price',
    'staging.order_items',
    'NEGATIVE_VALUE_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.order_items
WHERE price < 0 OR freight_value < 0;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'negative_payment_value',
    'staging.order_payments',
    'NEGATIVE_VALUE_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.order_payments
WHERE payment_value < 0;

-- ============================================================
-- 6. Review Score Range Check
-- ============================================================

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'invalid_review_score',
    'staging.order_reviews',
    'RANGE_CHECK',
    COUNT(*),
    'MEDIUM',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.order_reviews
WHERE review_score < 1 OR review_score > 5;

-- ============================================================
-- 7. Date Logic Checks
-- ============================================================

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'delivery_before_purchase',
    'staging.orders',
    'DATE_LOGIC_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'approval_before_purchase',
    'staging.orders',
    'DATE_LOGIC_CHECK',
    COUNT(*),
    'MEDIUM',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;

-- ============================================================
-- 8. Foreign Key / Orphan Record Checks
-- ============================================================

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'orders_missing_customer_reference',
    'staging.orders',
    'FOREIGN_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.orders o
LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'order_items_missing_order_reference',
    'staging.order_items',
    'FOREIGN_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.order_items oi
LEFT JOIN staging.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'order_items_missing_product_reference',
    'staging.order_items',
    'FOREIGN_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.order_items oi
LEFT JOIN staging.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'order_items_missing_seller_reference',
    'staging.order_items',
    'FOREIGN_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.order_items oi
LEFT JOIN staging.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'payments_missing_order_reference',
    'staging.order_payments',
    'FOREIGN_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.order_payments p
LEFT JOIN staging.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

INSERT INTO audit.data_quality_log (
    check_name, table_name, check_type, issue_count, severity, check_status
)
SELECT
    'reviews_missing_order_reference',
    'staging.order_reviews',
    'FOREIGN_KEY_CHECK',
    COUNT(*),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END
FROM staging.order_reviews r
LEFT JOIN staging.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- ============================================================
-- 9. Store rejected records for important failed checks
-- ============================================================

INSERT INTO audit.etl_reject_records (
    source_table, record_key, rule_name, error_description
)
SELECT
    'staging.orders',
    order_id,
    'delivery_before_purchase',
    'Delivered customer date is earlier than purchase timestamp.'
FROM staging.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date < order_purchase_timestamp;

INSERT INTO audit.etl_reject_records (
    source_table, record_key, rule_name, error_description
)
SELECT
    'staging.order_items',
    order_id,
    'negative_order_item_price',
    'Price or freight value is negative.'
FROM staging.order_items
WHERE price < 0 OR freight_value < 0;

INSERT INTO audit.etl_reject_records (
    source_table, record_key, rule_name, error_description
)
SELECT
    'staging.order_payments',
    order_id,
    'negative_payment_value',
    'Payment value is negative.'
FROM staging.order_payments
WHERE payment_value < 0;

INSERT INTO audit.etl_reject_records (
    source_table, record_key, rule_name, error_description
)
SELECT
    'staging.order_reviews',
    order_id,
    'invalid_review_score',
    'Review score is outside valid range 1 to 5.'
FROM staging.order_reviews
WHERE review_score < 1 OR review_score > 5;

-- ============================================================
-- 10. Finish ETL Quality Run Log
-- ============================================================

UPDATE audit.etl_run_log
SET
    end_time = CURRENT_TIMESTAMP,
    status = 'COMPLETED',
    rows_checked = (
        SELECT
            (SELECT COUNT(*) FROM staging.customers)
          + (SELECT COUNT(*) FROM staging.geolocation)
          + (SELECT COUNT(*) FROM staging.order_items)
          + (SELECT COUNT(*) FROM staging.order_payments)
          + (SELECT COUNT(*) FROM staging.order_reviews)
          + (SELECT COUNT(*) FROM staging.orders)
          + (SELECT COUNT(*) FROM staging.products)
          + (SELECT COUNT(*) FROM staging.sellers)
          + (SELECT COUNT(*) FROM staging.product_category_translation)
    ),
    rows_rejected = (
        SELECT COUNT(*)
        FROM audit.etl_reject_records
    ),
    message = 'Data quality validation completed for staging layer.'
WHERE run_id = (
    SELECT MAX(run_id)
    FROM audit.etl_run_log
    WHERE pipeline_name = 'olist_ecommerce_pipeline'
      AND run_step = 'data_quality_checks'
);