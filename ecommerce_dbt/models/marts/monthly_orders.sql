{{ config(materialized='table') }}

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::DATE AS order_month,
    COUNT(*) AS total_orders
FROM {{ ref('stg_orders') }}
GROUP BY 1
ORDER BY 1