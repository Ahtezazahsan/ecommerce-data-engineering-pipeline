from db_connection import get_connection


PIPELINE_NAME = "incremental_orders_pipeline"


def main():
    conn = get_connection()

    try:
        with conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT last_loaded_timestamp
                    FROM audit.etl_control
                    WHERE pipeline_name = %s;
                """, (PIPELINE_NAME,))

                result = cursor.fetchone()

                if result is None:
                    raise ValueError("Pipeline not found in audit.etl_control.")

                last_loaded_timestamp = result[0]

                cursor.execute("""
                    SELECT COUNT(*), MAX(order_purchase_timestamp)
                    FROM staging.orders
                    WHERE order_purchase_timestamp > %s;
                """, (last_loaded_timestamp,))

                candidate_rows, new_max_timestamp = cursor.fetchone()

                cursor.execute("""
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
                        dp.date_key,
                        da.date_key,
                        dcarrier.date_key,
                        dcustomer.date_key,
                        dest.date_key,
                        o.order_status,

                        CASE
                            WHEN o.order_delivered_customer_date IS NOT NULL
                             AND o.order_purchase_timestamp IS NOT NULL
                            THEN ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0, 2)
                            ELSE NULL
                        END,

                        CASE
                            WHEN o.order_delivered_customer_date IS NOT NULL
                             AND o.order_estimated_delivery_date IS NOT NULL
                            THEN ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0, 2)
                            ELSE NULL
                        END,

                        CASE
                            WHEN o.order_delivered_customer_date IS NOT NULL
                             AND o.order_estimated_delivery_date IS NOT NULL
                             AND o.order_delivered_customer_date > o.order_estimated_delivery_date
                            THEN TRUE
                            ELSE FALSE
                        END

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
                    WHERE o.order_purchase_timestamp > %s
                    ON CONFLICT (order_id)
                    DO NOTHING;
                """, (last_loaded_timestamp,))

                inserted_rows = cursor.rowcount
                skipped_rows = candidate_rows - inserted_rows

                if new_max_timestamp is not None:
                    cursor.execute("""
                        UPDATE audit.etl_control
                        SET
                            last_loaded_timestamp = %s,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE pipeline_name = %s;
                    """, (new_max_timestamp, PIPELINE_NAME))

                cursor.execute("""
                    INSERT INTO audit.incremental_load_log (
                        pipeline_name,
                        last_loaded_timestamp,
                        new_max_timestamp,
                        candidate_rows,
                        inserted_rows,
                        skipped_rows,
                        status,
                        message
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, 'COMPLETED', %s);
                """, (
                    PIPELINE_NAME,
                    last_loaded_timestamp,
                    new_max_timestamp,
                    candidate_rows,
                    inserted_rows,
                    skipped_rows,
                    "Incremental order load completed with duplicate-safe ON CONFLICT handling."
                ))

                print("Incremental ETL completed successfully.")
                print(f"Last loaded timestamp: {last_loaded_timestamp}")
                print(f"Candidate rows: {candidate_rows}")
                print(f"Inserted rows: {inserted_rows}")
                print(f"Skipped rows: {skipped_rows}")

    except Exception as error:
        conn.rollback()
        print("Incremental ETL failed.")
        print(f"Error: {error}")
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    main()