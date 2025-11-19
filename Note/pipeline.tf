# Azure Data Factory Pipeline for Data Ingestion

# This resource defines the primary data flow logic within ADF.
# It executes the Copy Data activity from the Raw Blob Storage into the PostgreSQL Staging table.

resource "azurerm_data_factory_pipeline" "ingestion_pipeline" {
  name             = "PL_Ingest_Raw311ToStaging"
  # This ID assumes your main ADF resource is named 'azurerm_data_factory.adf' in your other config files
  data_factory_id  = azurerm_data_factory.adf.id
  description      = "Copies NYC 311 data from the Azure Blob Landing Zone to the PostgreSQL Staging Table."
  
  # The core logic of the pipeline is defined in activities_json
  # Note: This JSON block utilizes the Linked Services and Datasets defined in data_factory.tf
  
  activities_json  = <<JSON
[
  {
    "name": "CopyRawToStagingDB",
    "type": "Copy",
    "dependsOn": [],
    "policy": {
      "timeout": "0.12:00:00",
      "retry": 0,
      "retryIntervalInSeconds": 30,
      "secureOutput": false,
      "secureInput": false
    },
    "userProperties": [],
    "typeProperties": {
      "source": {
        "type": "DelimitedTextSource",
        "storeSettings": {
          "type": "AzureBlobStorageReadSettings",
          "recursive": true
        },
        "formatSettings": {
          "type": "DelimitedTextReadSettings"
        }
      },
      "sink": {
        "type": "PostgreSqlSink",
        "writeBehavior": "insert"
      },
      "enableStaging": false,
      "inputs": [
        {
          "referenceName": "DS_Blob_NYC311_RawCSV",
          "type": "DatasetReference"
        }
      ],
      "outputs": [
        {
          "referenceName": "DS_DB_311_Staging",
          "type": "DatasetReference"
        }
      ]
    },
    "linkedServiceName": {
      "referenceName": "LS_DB_PostgreSQL_CivicPulse",
      "type": "LinkedServiceReference"
    }
  }
]
JSON
}
