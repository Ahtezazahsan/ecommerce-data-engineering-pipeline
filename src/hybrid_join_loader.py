from decimal import Decimal
from psycopg2.extras import execute_values
from db_connection import get_connection


BATCH_SIZE = 10000


def get_total_order_items(cursor):
    cursor.execute("SELECT COUNT(*) FROM staging.order_items;")
    return cursor.fetchone()[0]


def fetch_order_items_batch(cursor, limit, offset):
    cursor.execute("""
        SELECT
            order_id,
            order_item_id,
            product_id,
            seller_id,
            shipping_limit_date,
            price,
            freight_value
        FROM staging.order_items
        ORDER BY order_id, order_item_id
        LIMIT %s OFFSET %s;
    """, (limit, offset))

    columns = [desc[0] for desc in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def fetch_lookup_data(cursor, product_ids, seller_ids):
    product_lookup = {}
    seller_lookup = {}

    if product_ids:
        cursor.execute("""
            SELECT
                product_id,
                product_category_name,
                product_category_name_english
            FROM warehouse.dim_product
            WHERE product_id = ANY(%s);
        """, (list(product_ids),))

        for row in cursor.fetchall():
            product_lookup[row[0]] = {
                "product_category_name": row[1],
                "product_category_name_english": row[2],
            }

    if seller_ids:
        cursor.execute("""
            SELECT
                seller_id,
                seller_city,
                seller_state
            FROM warehouse.dim_seller
            WHERE seller_id = ANY(%s);
        """, (list(seller_ids),))

        for row in cursor.fetchall():
            seller_lookup[row[0]] = {
                "seller_city": row[1],
                "seller_state": row[2],
            }

    return product_lookup, seller_lookup


def build_enriched_records(incoming_items, product_lookup, seller_lookup):
    enriched_records = []

    for item in incoming_items:
        product = product_lookup.get(item["product_id"], {})
        seller = seller_lookup.get(item["seller_id"], {})

        price = item["price"] if item["price"] is not None else Decimal("0")
        freight = item["freight_value"] if item["freight_value"] is not None else Decimal("0")

        enriched_records.append((
            item["order_id"],
            item["order_item_id"],
            item["product_id"],
            product.get("product_category_name"),
            product.get("product_category_name_english"),
            item["seller_id"],
            seller.get("seller_city"),
            seller.get("seller_state"),
            price,
            freight,
            price + freight,
            item["shipping_limit_date"],
        ))

    return enriched_records


def bulk_insert_enriched_records(cursor, records):
    if not records:
        return 0

    insert_sql = """
        INSERT INTO warehouse.hybrid_join_enriched_order_items (
            order_id,
            order_item_sequence,
            product_id,
            product_category_name,
            product_category_name_english,
            seller_id,
            seller_city,
            seller_state,
            item_price,
            freight_value,
            total_item_cost,
            shipping_limit_date
        )
        VALUES %s;
    """

    execute_values(cursor, insert_sql, records, page_size=1000)
    return len(records)


def main():
    conn = get_connection()

    try:
        with conn:
            with conn.cursor() as cursor:
                total_rows = get_total_order_items(cursor)
                print(f"Total staging.order_items records: {total_rows}")

                print("Clearing previous Hybrid Join output...")
                cursor.execute("TRUNCATE TABLE warehouse.hybrid_join_enriched_order_items RESTART IDENTITY;")

                total_inserted = 0
                offset = 0
                batch_number = 1

                while offset < total_rows:
                    print(f"\nProcessing batch {batch_number} | Offset: {offset}")

                    incoming_items = fetch_order_items_batch(cursor, BATCH_SIZE, offset)

                    if not incoming_items:
                        break

                    product_ids = {
                        item["product_id"]
                        for item in incoming_items
                        if item["product_id"] is not None
                    }

                    seller_ids = {
                        item["seller_id"]
                        for item in incoming_items
                        if item["seller_id"] is not None
                    }

                    product_lookup, seller_lookup = fetch_lookup_data(
                        cursor,
                        product_ids,
                        seller_ids
                    )

                    enriched_records = build_enriched_records(
                        incoming_items,
                        product_lookup,
                        seller_lookup
                    )

                    inserted = bulk_insert_enriched_records(cursor, enriched_records)
                    total_inserted += inserted

                    print(f"Batch inserted: {inserted}")
                    print(f"Total inserted so far: {total_inserted}")

                    offset += BATCH_SIZE
                    batch_number += 1

                print("\nFull dataset Hybrid Join enrichment completed.")
                print(f"Total enriched records loaded: {total_inserted}")

    except Exception as error:
        conn.rollback()
        print("Hybrid Join full dataset loader failed.")
        print(f"Error: {error}")
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    main()