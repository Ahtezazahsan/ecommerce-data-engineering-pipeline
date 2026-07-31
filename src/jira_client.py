import os
import requests
from dotenv import load_dotenv

load_dotenv()

JIRA_BASE_URL = os.getenv("JIRA_BASE_URL")
JIRA_EMAIL = os.getenv("JIRA_EMAIL")
JIRA_API_TOKEN = os.getenv("JIRA_API_TOKEN")
JIRA_PROJECT_KEY = os.getenv("JIRA_PROJECT_KEY")


def create_jira_issue(summary: str, description: str, labels=None) -> str | None:
    """
    Creates a Jira work item in the configured Jira project.
    Used for ETL monitoring, data quality failures, and pipeline alerts.
    """
    if labels is None:
        labels = ["etl", "data-engineering"]

    if not all([JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN, JIRA_PROJECT_KEY]):
        raise ValueError(
            "Missing Jira configuration. Check JIRA_BASE_URL, JIRA_EMAIL, "
            "JIRA_API_TOKEN, and JIRA_PROJECT_KEY in .env file."
        )

    url = f"{JIRA_BASE_URL}/rest/api/3/issue"

    payload = {
        "fields": {
            "project": {"key": JIRA_PROJECT_KEY},
            "summary": summary,
            "description": {
                "type": "doc",
                "version": 1,
                "content": [
                    {
                        "type": "paragraph",
                        "content": [
                            {
                                "type": "text",
                                "text": description
                            }
                        ]
                    }
                ]
            },
            "issuetype": {"name": "Task"},
            "labels": labels
        }
    }

    response = requests.post(
        url,
        json=payload,
        auth=(JIRA_EMAIL, JIRA_API_TOKEN),
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json"
        },
        timeout=30
    )

    if response.status_code not in (200, 201):
        print("Failed to create Jira issue.")
        print("Status code:", response.status_code)
        print("Response:", response.text)
        return None

    issue_key = response.json().get("key")
    print(f"Jira issue created successfully: {issue_key}")
    return issue_key