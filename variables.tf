variable "db_password" {
  description = "The administrator password for the PostgreSQL Flexible Server."
  type        = string
  sensitive   = true
}

variable "azure_region" {
  description = "The Azure region to deploy resources into."
  type        = string
  default     = "centralus" # CHANGED from "eastus" to avoid LocationIsOfferRestricted error
}

variable "environment_name" {
  description = "The name of the environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
  default     = "dev"
}

variable "db_sku" {
  description = "The SKU name for the PostgreSQL Flexible Server (e.g., B_Standard_B1ms)."
  type        = string
  default     = "B_Standard_B1ms"
}
