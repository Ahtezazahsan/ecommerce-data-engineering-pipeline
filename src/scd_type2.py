import hashlib
from datetime import datetime
from db_connection import get_connection


def build_hash(row):
    """
    Creates a hash from product attributes.
    If any tracked product attribute changes, the hash will change.
    """
    values = [
        row.get("product_category_name"),
        row.get("product_category_name_english"),
        row.get("product_name_length"),
        row.get("product_description_length"),
        row.get("product_photos_qty"),
        row.get("product_weight_g"),
        row.get("product_length_cm"),
        row.get("product_height_cm"),
        row.get("product_width_cm"),
    ]

    combined = "|".join("" if value is None else str(value) for value in values)
    return hashlib.md5(combined.encode("utf-8")).hexdigest()


def load_initial_scd2(cursor):
    """
    Loads current products from warehouse.dim_product into dim_product_scd2.
    """
    cursor.execute("SELECT COUNT(*) FROM warehouse.dim_product_scd2;")
    existing_count = cursor.fetchone()[0]

    if existing_count > 0:
        print("SCD2 table already has data. Initial load skipped.")
        return

    cursor.execute("""
        SELECT
            product_id,
            product_category_name,
            product_category_name_english,
            product_name_length,
            product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm
        FROM warehouse.dim_product;
    """)

    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]

    insert_sql = """
        INSERT INTO warehouse.dim_product_scd2 (
            product_id,
            product_category_name,
            product_category_name_english,
            product_name_length,
            product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm,
            effective_start_date,
            effective_end_date,
            is_current,
            record_hash
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NULL, TRUE, %s);
    """

    now = datetime.now()

    for row_tuple in rows:
        row = dict(zip(columns, row_tuple))
        record_hash = build_hash(row)

        cursor.execute(insert_sql, (
            row["product_id"],
            row["product_category_name"],
            row["product_category_name_english"],
            row["product_name_length"],
            row["product_description_length"],
            row["product_photos_qty"],
            row["product_weight_g"],
            row["product_length_cm"],
            row["product_height_cm"],
            row["product_width_cm"],
            now,
            record_hash,
        ))

    print(f"Initial SCD2 load completed. Rows inserted: {len(rows)}")


def simulate_product_updates(cursor):
    """
    Simulates product master-data changes for SCD Type 2 demonstration.
    In a real job, this would come from a new daily product master file.
    """
    cursor.execute("""
        SELECT
            product_id,
            product_category_name,
            product_category_name_english,
            product_name_length,
            product_description_length,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm
        FROM warehouse.dim_product_scd2
        WHERE is_current = TRUE
          AND product_id IS NOT NULL
        LIMIT 5;
    """)

    rows = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]

    updated_rows = []

    for row_tuple in rows:
        row = dict(zip(columns, row_tuple))

        row["product_weight_g"] = (row["product_weight_g"] or 0) + 100
        row["product_category_name_english"] = (
            str(row["product_category_name_english"]) + "_updated"
            if row["product_category_name_english"] is not None
            else "updated_category"
        )

        updated_rows.append(row)

    return updated_rows


def apply_scd2_updates(cursor, updated_rows):
    """
    Applies SCD Type 2 logic:
    1. Compare new row hash with current row hash.
    2. If changed, close old record.
    3. Insert new current version.
    """
    now = datetime.now()
    changed_count = 0

    for row in updated_rows:
        new_hash = build_hash(row)

        cursor.execute("""
            SELECT product_scd_key, record_hash
            FROM warehouse.dim_product_scd2
            WHERE product_id = %s
              AND is_current = TRUE;
        """, (row["product_id"],))

        current_record = cursor.fetchone()

        if current_record is None:
            continue

        product_scd_key, current_hash = current_record

        if new_hash != current_hash:
            cursor.execute("""
                UPDATE warehouse.dim_product_scd2
                SET
                    effective_end_date = %s,
                    is_current = FALSE
                WHERE product_scd_key = %s;
            """, (now, product_scd_key))

            cursor.execute("""
                INSERT INTO warehouse.dim_product_scd2 (
                    product_id,
                    product_category_name,
                    product_category_name_english,
                    product_name_length,
                    product_description_length,
                    product_photos_qty,
                    product_weight_g,
                    product_length_cm,
                    product_height_cm,
                    product_width_cm,
                    effective_start_date,
                    effective_end_date,
                    is_current,
                    record_hash
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NULL, TRUE, %s);
            """, (
                row["product_id"],
                row["product_category_name"],
                row["product_category_name_english"],
                row["product_name_length"],
                row["product_description_length"],
                row["product_photos_qty"],
                row["product_weight_g"],
                row["product_length_cm"],
                row["product_height_cm"],
                row["product_width_cm"],
                now,
                new_hash,
            ))

            changed_count += 1

    print(f"SCD2 changed products inserted as new versions: {changed_count}")


def main():
    conn = get_connection()

    try:
        with conn:
            with conn.cursor() as cursor:
                load_initial_scd2(cursor)

                print("Simulating product master-data changes...")
                updated_rows = simulate_product_updates(cursor)

                print("Applying SCD Type 2 updates...")
                apply_scd2_updates(cursor, updated_rows)

                print("SCD Type 2 process completed successfully.")

    except Exception as error:
        conn.rollback()
        print("SCD Type 2 process failed.")
        print(f"Error: {error}")
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    main()