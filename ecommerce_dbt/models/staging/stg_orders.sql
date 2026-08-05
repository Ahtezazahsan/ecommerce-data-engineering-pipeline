{{ config(materialized='view') }}

SELECT
    TRIM(order_id) AS order_id,
    TRIM(customer_id) AS customer_id,
    TRIM(order_status) AS order_status,
    NULLIF(order_purchase_timestamp, '')::TIMESTAMP
        AS order_purchase_timestamp
FROM {{ source('raw', 'olist_orders_dataset') }}