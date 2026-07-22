# Olist E-Commerce Dataset Profile
This file was generated automatically from the raw CSV files.

## olist_customers_dataset.csv
- Rows: 99441
- Columns: 5

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| customer_id | str | 0 | 06b8999e2fba1a1fbc88172c00ba8bc7 |
| customer_unique_id | str | 0 | 861eff4711a542e4b93843c6dd7febb0 |
| customer_zip_code_prefix | int64 | 0 | 14409 |
| customer_city | str | 0 | franca |
| customer_state | str | 0 | SP |

## olist_geolocation_dataset.csv
- Rows: 1000163
- Columns: 5

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| geolocation_zip_code_prefix | int64 | 0 | 1037 |
| geolocation_lat | float64 | 0 | -23.54562128115268 |
| geolocation_lng | float64 | 0 | -46.63929204800168 |
| geolocation_city | str | 0 | sao paulo |
| geolocation_state | str | 0 | SP |

## olist_order_items_dataset.csv
- Rows: 112650
- Columns: 7

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| order_id | str | 0 | 00010242fe8c5a6d1ba2dd792cb16214 |
| order_item_id | int64 | 0 | 1 |
| product_id | str | 0 | 4244733e06e7ecb4970a6e2683c13e61 |
| seller_id | str | 0 | 48436dade18ac8b2bce089ec2a041202 |
| shipping_limit_date | str | 0 | 2017-09-19 09:45:35 |
| price | float64 | 0 | 58.9 |
| freight_value | float64 | 0 | 13.29 |

## olist_order_payments_dataset.csv
- Rows: 103886
- Columns: 5

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| order_id | str | 0 | b81ef226f3fe1789b1e8b2acac839d17 |
| payment_sequential | int64 | 0 | 1 |
| payment_type | str | 0 | credit_card |
| payment_installments | int64 | 0 | 8 |
| payment_value | float64 | 0 | 99.33 |

## olist_order_reviews_dataset.csv
- Rows: 104719
- Columns: 7

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| review_id | str | 0 | 7bc2406110b926393aa56f80a40eba40 |
| order_id | str | 0 | 73fc7af87114b39712e6da79b0a377eb |
| review_score | int64 | 0 | 4 |
| review_comment_title | str | 4410 | recomendo |
| review_comment_message | str | 2931 | Recebi bem antes do prazo estipulado. |
| review_creation_date | str | 0 | 1/18/2018 0:00 |
| review_answer_timestamp | str | 0 | 1/18/2018 21:46 |

## olist_orders_dataset.csv
- Rows: 99441
- Columns: 8

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| order_id | str | 0 | e481f51cbdc54678b7cc49136f2d6af7 |
| customer_id | str | 0 | 9ef432eb6251297304e76186b10a928d |
| order_status | str | 0 | delivered |
| order_purchase_timestamp | str | 0 | 10/2/2017 10:56 |
| order_approved_at | str | 10 | 10/2/2017 11:07 |
| order_delivered_carrier_date | str | 78 | 10/4/2017 19:55 |
| order_delivered_customer_date | str | 142 | 10/10/2017 21:25 |
| order_estimated_delivery_date | str | 0 | 10/18/2017 0:00 |

## olist_products_dataset.csv
- Rows: 32951
- Columns: 9

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| product_id | str | 0 | 1e9e8ef04dbcff4541ed26657ea517e5 |
| product_category_name | str | 102 | perfumaria |
| product_name_lenght | float64 | 102 | 40.0 |
| product_description_lenght | float64 | 102 | 287.0 |
| product_photos_qty | float64 | 102 | 1.0 |
| product_weight_g | int64 | 0 | 225 |
| product_length_cm | int64 | 0 | 16 |
| product_height_cm | int64 | 0 | 10 |
| product_width_cm | int64 | 0 | 14 |

## olist_sellers_dataset.csv
- Rows: 3095
- Columns: 4

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| seller_id | str | 0 | 3442f8959a84dea7ee197c632cb2df15 |
| seller_zip_code_prefix | int64 | 0 | 13023 |
| seller_city | str | 0 | campinas |
| seller_state | str | 0 | SP |

## product_category_name_translation.csv
- Rows: 71
- Columns: 2

| Column | Pandas inferred dtype | Missing in sample | Example value |
|---|---|---:|---|
| product_category_name | str | 0 | beleza_saude |
| product_category_name_english | str | 0 | health_beauty |

