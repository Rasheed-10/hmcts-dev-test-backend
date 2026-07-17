output "resource_group_name" {
  description = "Name of the resource group containing the service."
  value       = azurerm_resource_group.service.name
}

output "container_app_name" {
  description = "Name of the Azure Container App."
  value       = azurerm_container_app.service.name
}

output "application_url" {
  description = "Public URL of the deployed application."
  value       = "https://${azurerm_container_app.service.latest_revision_fqdn}"
}

output "postgresql_server_fqdn" {
  description = "Fully qualified hostname of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.service.fqdn
}

output "database_name" {
  description = "Name of the PostgreSQL application database."
  value       = azurerm_postgresql_flexible_server_database.application.name
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault."
  value       = azurerm_key_vault.service.name
}

output "container_app_identity_id" {
  description = "Resource ID of the user-assigned identity used by the Container App."
  value       = azurerm_user_assigned_identity.container_app.id
}