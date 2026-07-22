from pathlib import Path
from db_connection import get_connection

RAW_DIR = Path("data/raw")

CSV_TABLE_MAP = {
    "olist_customers_dataset.csv": "olist_customers_dataset",
    "olist_geolocation_dataset.csv": "olist_geolocation_dataset",
    "olist_order_items_dataset.csv": "olist_order_items_dataset",
    "olist_order_payments_dataset.csv": "olist_order_payments_dataset",
    "olist_order_reviews_dataset.csv": "olist_order_reviews_dataset",
    "olist_orders_dataset.csv": "olist_orders_dataset",
    "olist_products_dataset.csv": "olist_products_dataset",
    "olist_sellers_dataset.csv": "olist_sellers_dataset",
    "product_category_name_translation.csv": "product_category_name_translation",
}


def truncate_raw_tables(cursor):
    """
    Clears old raw data before loading fresh CSV data.
    This avoids duplicate rows if the script is run multiple times.
    """
    for table_name in CSV_TABLE_MAP.values():
        cursor.execute(f"TRUNCATE TABLE raw.{table_name};")


def load_csv_to_raw(cursor, csv_file: Path, table_name: str):
    """
    Loads a CSV file into the matching PostgreSQL raw table using COPY.
    COPY is faster than row-by-row insert.
    """
    copy_sql = f"""
        COPY raw.{table_name}
        FROM STDIN
        WITH (
            FORMAT CSV,
            HEADER TRUE,
            DELIMITER ',',
            QUOTE '"',
            ENCODING 'UTF8'
        );
    """

    with csv_file.open("r", encoding="utf-8", newline="") as file:
        cursor.copy_expert(copy_sql, file)


def main():
    if not RAW_DIR.exists():
        raise FileNotFoundError("data/raw folder not found.")

    missing_files = [
        file_name for file_name in CSV_TABLE_MAP
        if not (RAW_DIR / file_name).exists()
    ]

    if missing_files:
        raise FileNotFoundError(
            "Missing CSV files in data/raw folder: " + ", ".join(missing_files)
        )

    conn = get_connection()

    try:
        with conn:
            with conn.cursor() as cursor:
                print("Clearing old raw tables...")
                truncate_raw_tables(cursor)

                print("Loading CSV files into raw schema...\n")

                for file_name, table_name in CSV_TABLE_MAP.items():
                    csv_path = RAW_DIR / file_name
                    print(f"Loading {file_name} -> raw.{table_name}")
                    load_csv_to_raw(cursor, csv_path, table_name)

                print("\nAll raw CSV files loaded successfully.")

    except Exception as error:
        conn.rollback()
        print("\nETL failed.")
        print(f"Error: {error}")
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    main()