# -----------------------------
# Resource Group Output
# -----------------------------
output "resource_group_name" {
  description = "The name of the Azure Resource Group."
  value       = azurerm_resource_group.urban_resource.name
}

# -----------------------------
# PostgreSQL Flexible Server Outputs
# -----------------------------
output "postgresql_server_name" {
  description = "The name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.db.name
}

output "postgresql_host" {
  description = "The Fully Qualified Domain Name (FQDN) for the PostgreSQL Server."
  value       = azurerm_postgresql_flexible_server.db.fqdn
}

output "postgresql_connection_string" {
  description = "PostgreSQL connection string (for use in Data Factory or Python apps)."
  value       = "postgresql://${azurerm_postgresql_flexible_server.db.administrator_login}:${var.db_password}@${azurerm_postgresql_flexible_server.db.fqdn}:5432/postgres"
  sensitive   = true
}

# -----------------------------
# Azure Storage Account Outputs
# -----------------------------
output "storage_account_name" {
  description = "The name of the Azure Storage Account (Blob)."
  value       = azurerm_storage_account.blob.name
}

output "storage_connection_string" {
  description = "Primary connection string for the Azure Storage Account."
  value       = azurerm_storage_account.blob.primary_connection_string
  sensitive   = true
}

# -----------------------------
# Storage Container Output
# -----------------------------
output "raw_data_container_name" {
  description = "The name of the raw data container (must match Python script)."
  value       = azurerm_storage_container.rawdata.name
}

# -----------------------------
# Azure Data Factory Output
# -----------------------------
output "data_factory_name" {
  description = "The name of the Azure Data Factory instance."
  value       = azurerm_data_factory.adf.name
}
