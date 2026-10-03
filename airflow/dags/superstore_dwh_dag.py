from datetime import timedelta
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

PROJECT_DIR = "/opt/airflow/project"
DBT_DIR = f"{PROJECT_DIR}/dbt_project"
VENV_BIN = "/opt/dbt_venv/bin"

# every dbt command runs from the dbt project folder, using its own profiles.yml
# --no-partial-parse: target/ is shared with dbt on the host, whose parse cache breaks the container's dbt
DBT = f"cd {DBT_DIR} && {VENV_BIN}/dbt"
DBT_FLAGS = "--profiles-dir . --target dev --no-partial-parse"

default_args = {
    "owner": "dataops",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id="superstore_dwh",
    description="Superstore.xlsx -> ODS -> dbt staging -> dbt marts (DWH)",
    schedule="@daily",
    start_date=pendulum.datetime(2026, 10, 1, tz="UTC"),
    catchup=False,
    default_args=default_args,
    tags=["dbt", "duckdb", "superstore"],
) as dag:

    dbt_debug = BashOperator(
        task_id="dbt_debug",
        bash_command=f"{DBT} debug {DBT_FLAGS}",
    )

    load_to_ods = BashOperator(
        task_id="load_to_ods",
        bash_command=f"{VENV_BIN}/python {PROJECT_DIR}/scripts/load_to_ods.py",
    )

    dbt_test_sources = BashOperator(
        task_id="dbt_test_sources",
        bash_command=f"{DBT} test --select source:ods --indirect-selection cautious {DBT_FLAGS}",
    )

    # each layer is built, then tested right away, so a failure points to the exact layer
    dbt_run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=f"{DBT} run --select staging {DBT_FLAGS}",
    )

    # source tests also live under models/staging, they already ran in dbt_test_sources
    dbt_test_staging = BashOperator(
        task_id="dbt_test_staging",
        bash_command=f"{DBT} test --select staging --exclude source:ods {DBT_FLAGS}",
    )

    dbt_run_marts = BashOperator(
        task_id="dbt_run_marts",
        bash_command=f"{DBT} run --select marts {DBT_FLAGS}",
    )

    # also picks up the ODS <-> fact_sales reconciliation test, since it depends on fact_sales
    dbt_test_marts = BashOperator(
        task_id="dbt_test_marts",
        bash_command=f"{DBT} test --select marts {DBT_FLAGS}",
    )

    (
        dbt_debug
        >> load_to_ods
        >> dbt_test_sources
        >> dbt_run_staging
        >> dbt_test_staging
        >> dbt_run_marts
        >> dbt_test_marts
    )
