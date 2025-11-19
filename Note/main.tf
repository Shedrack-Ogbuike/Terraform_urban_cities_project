// Define the core resource group
resource "azurerm_resource_group" "urban_resource" {

  # Using environment_name variable in the name and location variable
  name     = "urban-rg-${var.environment_name}"
  location = var.azure_region

  tags = {
    Project     = "CivicPulse311"
    Component   = "Core"
    Environment = var.environment_name
  }
}

# --- Storage Account (Raw Data Landing Zone) ---
resource "azurerm_storage_account" "blob" {

  # Name includes environment and a random suffix for global uniqueness
  name                     = "urbanstorage${var.environment_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.urban_resource.name
  location                 = azurerm_resource_group.urban_resource.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Low-cost, locally redundant storage

  tags = {
    Component   = "BlobStorage"
    Environment = var.environment_name
  }
}

# Container for raw CSV files (Matches BLOB_CONTAINER in nyc_ingest.py: "urban-rawdata")
resource "azurerm_storage_container" "rawdata" {

  # FIXED: Changed underscore to hyphen
  name                  = "urban-rawdata"
  storage_account_name  = azurerm_storage_account.blob.name
  container_access_type = "private"
}

# --- PostgreSQL Flexible Server (Data Warehouse) ---
resource "azurerm_postgresql_flexible_server" "db" {

  # Name includes environment and random suffix
  name                = "urban-db-${var.environment_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.urban_resource.name
  location            = azurerm_resource_group.urban_resource.location
  administrator_login = "adminuser"
  administrator_password = var.db_password
  version                = "13"
  storage_mb             = 32768
  sku_name               = var.db_sku # Uses the db_sku variable
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false # FIXED: Changed "Disabled" string to boolean false

  # FIX: Enable public access temporarily for ease of use in dev
  public_network_access_enabled = true

  tags = {
    Component   = "PostgreSQL"
    Environment = var.environment_name
  }

  # FIX: Ignore the 'zone' attribute, which was imported from Azure but is not
  # defined in the configuration, to resolve the final "zone can only be changed" error.
  lifecycle {
    ignore_changes = [
      "zone",
    ]
  }
}

# Database definition - CORRECTED RESOURCE TYPE
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "civicpulse"
  server_id = azurerm_postgresql_flexible_server.db.id
}

# Firewall rule 1: Allow Azure services (like Data Factory) to connect to the DB
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name      = "AllowAzureServices"
  server_id = azurerm_postgresql_flexible_server.db.id

  # Setting both start and end to 0.0.0.0 allows all Azure services to connect
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# REMOVED: Firewall rule 2: 'allow_admin_ip' is removed as you do not want to use an explicit IP address.

# --- Azure Data Factory (Orchestration and Transformation) ---
resource "azurerm_data_factory" "adf" {

  # Name includes environment and random suffix
  name                = "urbancitydf-${var.environment_name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.urban_resource.location
  resource_group_name = azurerm_resource_group.urban_resource.name

  tags = {
    Component   = "DataFactory"
    Environment = var.environment_name
  }
}

# Helper resource to generate unique suffixes for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}
