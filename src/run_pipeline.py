import subprocess
import sys
from pathlib import Path

from db_connection import get_connection


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SQL_FOLDER = PROJECT_ROOT / "sql"
SRC_FOLDER = PROJECT_ROOT / "src"


def run_sql_script(file_name: str) -> None:
    """Run one SQL file inside a database transaction."""

    sql_path = SQL_FOLDER / file_name

    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    sql_content = sql_path.read_text(encoding="utf-8-sig")

    if not sql_content.strip():
        raise ValueError(f"SQL file is empty: {sql_path}")

    print(f"\n{'=' * 60}")
    print(f"Running SQL: {file_name}")
    print(f"{'=' * 60}")

    connection = get_connection()

    try:
        with connection:
            with connection.cursor() as cursor:
                cursor.execute(sql_content)

        print(f"Completed SQL: {file_name}")

    finally:
        connection.close()


def run_python_script(file_name: str) -> None:
    """Run one existing Python ETL module."""

    script_path = SRC_FOLDER / file_name

    if not script_path.exists():
        raise FileNotFoundError(f"Python file not found: {script_path}")

    print(f"\n{'=' * 60}")
    print(f"Running Python: {file_name}")
    print(f"{'=' * 60}")

    subprocess.run(
        [sys.executable, str(script_path)],
        cwd=PROJECT_ROOT,
        check=True,
    )

    print(f"Completed Python: {file_name}")


def validate_deployment() -> None:
    """Confirm that the final warehouse and mart layers exist."""

    validation_query = """
        SELECT
            (SELECT COUNT(*) FROM raw.olist_orders_dataset) AS raw_orders,
            (SELECT COUNT(*) FROM staging.orders) AS staging_orders,
            (SELECT COUNT(*) FROM warehouse.fact_orders) AS warehouse_orders,
            (SELECT COUNT(*) FROM mart.monthly_revenue_view) AS mart_rows;
    """

    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute(validation_query)
            raw_orders, staging_orders, warehouse_orders, mart_rows = cursor.fetchone()

        print("\nDeployment validation:")
        print(f"Raw orders:       {raw_orders}")
        print(f"Staging orders:   {staging_orders}")
        print(f"Warehouse orders: {warehouse_orders}")
        print(f"Mart rows:        {mart_rows}")

    finally:
        connection.close()


def main() -> None:
    print("\nStarting complete e-commerce data pipeline deployment...")

    # Database schemas and empty raw tables
    run_sql_script("01_create_schemas.sql")
    run_sql_script("02_create_raw_tables.sql")

    # Load CSV files into the raw layer
    run_python_script("load_raw.py")

    # Transform and validate data
    run_sql_script("03_create_staging_tables.sql")
    run_sql_script("04_data_quality_checks.sql")
    run_sql_script("05_create_warehouse_tables.sql")
    run_sql_script("06_advanced_etl_objects.sql")

    # Advanced ETL modules
    run_python_script("hybrid_join_loader.py")
    run_python_script("scd_type2.py")
    run_python_script("incremental_load.py")

    # Performance and reporting layers
    run_sql_script("07_partitioning_and_indexes.sql")
    run_sql_script("08_create_mart_views.sql")

    # Final verification
    validate_deployment()

    print("\nComplete pipeline deployment finished successfully.")


if __name__ == "__main__":
    main()