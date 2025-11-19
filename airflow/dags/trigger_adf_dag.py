from airflow.models.dag import DAG
from airflow.providers.postgres.operators.postgres_operator import PostgresOperator
from airflow.providers.microsoft.azure.operators.data_factory import AzureDataFactoryRunPipelineOperator
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
import pendulum
import os

# -------------------------------------------------------------------
# CONFIGURATION
# -------------------------------------------------------------------
BLOB_CONTAINER = "urban-rawdata"
ADF_CONN_ID = "azure_data_factory_connection"
POSTGRES_CONN_ID = "postgres_default"
ADF_FACTORY_NAME = "adf-urban-data-pipeline"
ADF_PIPELINE_NAME = "PL_Ingest_Raw311ToStaging"

# SQL file paths relative to the DAG folder
CREATE_STAGING_SQL_PATH = "create_staging_table.sql"
TRANSFORM_SQL_PATH = "nycdb.sql"

# Resolve the absolute path to the ingest script
DAG_FOLDER = os.path.dirname(os.path.abspath(__file__))
INGEST_SCRIPT_PATH = os.path.join(DAG_FOLDER, "nyc_ingest.py")

# -------------------------------------------------------------------
# DAG DEFINITION
# -------------------------------------------------------------------
with DAG(
    dag_id="nyc_full_etl_pipeline",
    start_date=days_ago(1),
    schedule="@daily",
    catchup=False,
    tags=["azure", "postgres", "etl", "nyc"],
    default_args={
        "owner": "airflow",
        "retries": 1,
        "retry_delay": pendulum.duration(minutes=5),
        "execution_timeout": pendulum.duration(minutes=30),
    },
) as dag:

    # 1. Ingestion: Run nyc_ingest.py via BashOperator
    ingest_to_blob = BashOperator(
        task_id="ingest_api_to_blob",
        bash_command=f"python dags/nyc_ingest.py",
        do_xcom_push=True,
    )

    # 2. Create staging table in Postgres
    create_staging_table = PostgresOperator(
        task_id="ensure_staging_table_exists",
        postgres_conn_id=POSTGRES_CONN_ID,
        sql=CREATE_STAGING_SQL_PATH,
    )

    # 3. Trigger Azure Data Factory pipeline
    trigger_adf_pipeline = AzureDataFactoryRunPipelineOperator(
        task_id="trigger_adf_pipeline_for_load",
        azure_data_factory_conn_id="azure_data_factory_connection",
        factory_name="urbancitydf-dev-w9f8bx",
        pipeline_name="PL_Ingest_Raw311ToStaging",
        resource_group_name="urban-rg-dev",
        wait_for_termination=True,
        parameters={
            "SourceFileName": "{{ task_instance.xcom_pull(task_ids='ingest_api_to_blob') }}",
            "RunDate": "{{ ds }}",
        },
    )

    # 4. Transform and load final table
    transform_data = PostgresOperator(
        task_id="transform_and_load_final_table",
        postgres_conn_id=POSTGRES_CONN_ID,
        sql=TRANSFORM_SQL_PATH,
    )

    # DAG task dependencies
    [ingest_to_blob, create_staging_table] >> trigger_adf_pipeline >> transform_data

