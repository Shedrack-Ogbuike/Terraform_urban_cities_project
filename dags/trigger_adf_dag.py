from airflow import DAG
from airflow.models.dag import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.microsoft.azure.operators.data_factory import AzureDataFactoryRunPipelineOperator
from airflow.operators.bash import BashOperator 
from airflow.utils.dates import days_ago
import pendulum


# -------------------------------------------------------------------
# CONFIGURATION
# -------------------------------------------------------------------
BLOB_CONTAINER = "urban-rawdata" 
ADF_CONN_ID = "azure_data_factory_connection" 
POSTGRES_CONN_ID = "postgres_default" # Connection ID for PostgreSQL
ADF_FACTORY_NAME = "adf-urban-data-pipeline" 
ADF_PIPELINE_NAME = "PL_Ingest_Raw311ToStaging"

# --- SQL File Paths (relative to the DAGs folder) ---
# NOTE: Ensure 'create_staging_table.sql' and 'nycdb.sql' are in the DAGs root folder.
CREATE_STAGING_SQL_PATH = "create_staging_table.sql" 
TRANSFORM_SQL_PATH = "nycdb.sql" 

# -------------------------------------------------------------------
# AIRFLOW DAG DEFINITION
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
    }
) as dag:
    
    # 1. PYTHON INGESTION STEP (E: Extract & Load to Blob)
    # Executes the external script 'python/nyc_ingest.py'.
    # This script's final 'print(filename)' is captured by xcom_push=True.
    ingest_to_blob = BashOperator(
        task_id="ingest_api_to_blob",
        # Command to execute the Python script in its subfolder
        bash_command="python {{ dag_run.dag.dag_folder }}/python/nyc_ingest.py",
        xcom_push=True, # Captures the filename and passes it to the next task
    )

    # 2. CREATE STAGING TABLE STEP (Setup)
    # Ensures the staging table schema is ready in PostgreSQL before ADF loads data.
    create_staging_table = PostgresOperator(
        task_id="ensure_staging_table_exists",
        postgres_conn_id=POSTGRES_CONN_ID,
        sql=CREATE_STAGING_SQL_PATH, 
    )
    
    # 3. AZURE DATA FACTORY LOAD STEP (L: Load to Postgres)
    trigger_adf_pipeline = AzureDataFactoryRunPipelineOperator(
        task_id="trigger_adf_pipeline_for_load",
        azure_data_factory_conn_id=ADF_CONN_ID, 
        factory_name=ADF_FACTORY_NAME, 
        pipeline_name=ADF_PIPELINE_NAME,
        wait_for_termination=True,
        # XCom Pull: Retrieves the filename from the BashOperator's output
        parameters={
            "SourceFileName": "{{ task_instance.xcom_pull(task_ids='ingest_api_to_blob') }}", 
            "RunDate": "{{ ds }}",
        },
    )

    # 4. TRANSFORMATION STEP (T: Transform)
    # Runs the nycdb.sql script to move data from staging to the final table.
    transform_data = PostgresOperator(
        task_id="transform_and_load_final_table",
        postgres_conn_id=POSTGRES_CONN_ID,
        sql=TRANSFORM_SQL_PATH, # Uses your file: nycdb.sql
    )

    # --- Set Dependencies ---
    # Ingestion (file created) and table setup must complete before ADF starts.
    # ADF runs next, followed by the transformation step.
    [ingest_to_blob, create_staging_table] >> trigger_adf_pipeline >> transform_data
