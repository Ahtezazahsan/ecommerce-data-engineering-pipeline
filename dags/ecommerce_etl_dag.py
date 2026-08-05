from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pendulum
import psycopg2
from airflow.sdk import dag, task


PROJECT_ROOT = Path("/opt/airflow/project")
SQL_FOLDER = PROJECT_ROOT / "sql"
SRC_FOLDER = PROJECT_ROOT / "src"

DB_SETTINGS = {
    "host": "host.docker.internal",
    "port": "5433",
    "dbname": "ecommerce_etl_db",
    "user": "ecommerce_etl_user",
    "password": "etl_docker_pass",
}


def get_database_connection():
    """Connect from the Airflow worker to e-commerce PostgreSQL."""
    return psycopg2.connect(**DB_SETTINGS)


@task(retries=1)
def run_sql_script(file_name: str) -> None:
    """Execute one existing project SQL file."""

    sql_path = SQL_FOLDER / file_name

    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    sql_content = sql_path.read_text(encoding="utf-8-sig")

    if not sql_content.strip():
        raise ValueError(f"SQL file is empty: {sql_path}")

    print(f"Starting SQL script: {file_name}")

    connection = get_database_connection()

    try:
        with connection:
            with connection.cursor() as cursor:
                cursor.execute(sql_content)
    finally:
        connection.close()

    print(f"Completed SQL script: {file_name}")


@task(retries=1)
def run_python_script(file_name: str) -> None:
    """Execute one existing Python ETL script."""

    script_path = SRC_FOLDER / file_name

    if not script_path.exists():
        raise FileNotFoundError(f"Python script not found: {script_path}")

    task_environment = os.environ.copy()
    task_environment.update(
        {
            "DB_HOST": DB_SETTINGS["host"],
            "DB_PORT": DB_SETTINGS["port"],
            "DB_NAME": DB_SETTINGS["dbname"],
            "DB_USER": DB_SETTINGS["user"],
            "DB_PASSWORD": DB_SETTINGS["password"],
        }
    )

    print(f"Starting Python script: {file_name}")

    subprocess.run(
        [sys.executable, str(script_path)],
        cwd=str(PROJECT_ROOT),
        env=task_environment,
        check=True,
    )

    print(f"Completed Python script: {file_name}")


@task
def validate_pipeline() -> None:
    """Validate the final raw, staging, warehouse and mart layers."""

    query = """
        SELECT
            (SELECT COUNT(*) FROM raw.olist_orders_dataset),
            (SELECT COUNT(*) FROM staging.orders),
            (SELECT COUNT(*) FROM warehouse.fact_orders),
            (SELECT COUNT(*) FROM mart.monthly_revenue_view);
    """

    connection = get_database_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute(query)
            raw_orders, staging_orders, warehouse_orders, mart_rows = (
                cursor.fetchone()
            )
    finally:
        connection.close()

    print("Final pipeline validation:")
    print(f"Raw orders: {raw_orders}")
    print(f"Staging orders: {staging_orders}")
    print(f"Warehouse orders: {warehouse_orders}")
    print(f"Mart rows: {mart_rows}")

    if raw_orders == 0 or warehouse_orders == 0 or mart_rows == 0:
        raise ValueError("Pipeline validation failed because a layer is empty.")


@dag(
    dag_id="ecommerce_etl_pipeline",
    schedule=None,
    start_date=pendulum.datetime(2026, 8, 1, tz="UTC"),
    catchup=False,
    max_active_runs=1,
    tags=["ecommerce", "etl", "postgresql"],
)
def ecommerce_etl_pipeline():
    """Run the complete e-commerce data engineering pipeline."""

    create_schemas = run_sql_script.override(
        task_id="create_schemas"
    )("01_create_schemas.sql")

    create_raw_tables = run_sql_script.override(
        task_id="create_raw_tables"
    )("02_create_raw_tables.sql")

    load_raw = run_python_script.override(
        task_id="load_raw_csv_files"
    )("load_raw.py")

    create_staging = run_sql_script.override(
        task_id="create_staging_tables"
    )("03_create_staging_tables.sql")

    data_quality = run_sql_script.override(
        task_id="run_data_quality_checks"
    )("04_data_quality_checks.sql")

    create_warehouse = run_sql_script.override(
        task_id="create_warehouse"
    )("05_create_warehouse_tables.sql")

    create_advanced_objects = run_sql_script.override(
        task_id="create_advanced_etl_objects"
    )("06_advanced_etl_objects.sql")

    hybrid_join = run_python_script.override(
        task_id="run_hybrid_join"
    )("hybrid_join_loader.py")

    scd_type2 = run_python_script.override(
        task_id="run_scd_type2"
    )("scd_type2.py")

    incremental_load = run_python_script.override(
        task_id="run_incremental_load"
    )("incremental_load.py")

    create_indexes = run_sql_script.override(
        task_id="create_partitions_and_indexes"
    )("07_partitioning_and_indexes.sql")

    create_marts = run_sql_script.override(
        task_id="create_mart_views"
    )("08_create_mart_views.sql")

    validation = validate_pipeline()

    (
        create_schemas
        >> create_raw_tables
        >> load_raw
        >> create_staging
        >> data_quality
        >> create_warehouse
        >> create_advanced_objects
        >> hybrid_join
        >> scd_type2
        >> incremental_load
        >> create_indexes
        >> create_marts
        >> validation
    )


ecommerce_etl_pipeline()