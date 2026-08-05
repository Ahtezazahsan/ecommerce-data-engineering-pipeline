import pendulum

from airflow.sdk import dag, task


@dag(
    dag_id="airflow_smoke_test",
    schedule=None,
    start_date=pendulum.datetime(2026, 8, 1, tz="UTC"),
    catchup=False,
    tags=["learning", "test"],
)
def airflow_smoke_test():
    """Confirm that the Airflow scheduler and worker are working."""

    @task(retries=1)
    def start_test() -> str:
        print("Airflow scheduler and worker are working correctly.")
        return "SUCCESS"

    @task
    def finish_test(status: str) -> None:
        print(f"Airflow smoke test completed with status: {status}")

    finish_test(start_test())


airflow_smoke_test()