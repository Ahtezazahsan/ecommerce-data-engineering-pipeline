from db_connection import get_connection
from jira_client import create_jira_issue


def get_failed_quality_checks(cursor):
    """
    Reads failed data quality checks from audit.data_quality_log.
    """
    cursor.execute("""
        SELECT
            check_name,
            table_name,
            check_type,
            issue_count,
            severity,
            check_status
        FROM audit.data_quality_log
        WHERE check_status = 'FAILED'
          AND issue_count > 0
        ORDER BY severity DESC, issue_count DESC;
    """)

    columns = [desc[0] for desc in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def build_description(failed_checks):
    """
    Builds Jira ticket description from failed data quality checks.
    """
    lines = []
    lines.append("Automated ETL data quality alert for the E-Commerce ETL Pipeline.")
    lines.append("")
    lines.append("The following data quality checks failed:")
    lines.append("")

    for check in failed_checks:
        lines.append(
            f"- Check: {check['check_name']} | "
            f"Table: {check['table_name']} | "
            f"Type: {check['check_type']} | "
            f"Issues: {check['issue_count']} | "
            f"Severity: {check['severity']}"
        )

    lines.append("")
    lines.append("Recommended action:")
    lines.append("Review audit.data_quality_log and audit.etl_reject_records in PostgreSQL.")
    lines.append("")
    lines.append("Database:")
    lines.append("ecommerce_etl_db")
    lines.append("")
    lines.append("Relevant project modules:")
    lines.append("- sql/04_data_quality_checks.sql")
    lines.append("- audit.data_quality_log")
    lines.append("- audit.etl_reject_records")

    return "\n".join(lines)


def main():
    conn = get_connection()

    try:
        with conn:
            with conn.cursor() as cursor:
                failed_checks = get_failed_quality_checks(cursor)

                if not failed_checks:
                    print("No failed data quality checks found. Jira ticket not created.")
                    return

                summary = (
                    f"ETL Data Quality Alert: "
                    f"{len(failed_checks)} failed checks in ecommerce_etl_db"
                )

                description = build_description(failed_checks)

                create_jira_issue(
                    summary=summary,
                    description=description,
                    labels=[
                        "etl",
                        "data-quality",
                        "postgresql",
                        "ecommerce-pipeline"
                    ]
                )

    finally:
        conn.close()


if __name__ == "__main__":
    main()