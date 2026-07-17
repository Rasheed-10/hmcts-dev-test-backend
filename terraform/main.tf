data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "service" {
  name     = "rg-${local.resource_suffix}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "service" {
  name                = "log-${local.resource_suffix}"
  location            = azurerm_resource_group.service.location
  resource_group_name = azurerm_resource_group.service.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_container_app_environment" "service" {
  name                       = "cae-${local.resource_suffix}"
  location                   = azurerm_resource_group.service.location
  resource_group_name        = azurerm_resource_group.service.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.service.id
  tags                       = local.common_tags
}

resource "azurerm_postgresql_flexible_server" "service" {
  name                = "psql-${local.resource_suffix}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.service.name
  location            = azurerm_resource_group.service.location

  administrator_login    = var.database_administrator_login
  administrator_password = var.database_administrator_password

  version    = "16"
  sku_name   = var.postgresql_sku_name
  storage_mb = 32768

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  authentication {
    password_auth_enabled         = true
    active_directory_auth_enabled = false
  }

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "application" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.service.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_key_vault" "service" {
  name = substr(
    "kv-${replace(var.application_name, "-", "")}-${random_string.suffix.result}",
    0,
    24
  )

  location            = azurerm_resource_group.service.location
  resource_group_name = azurerm_resource_group.service.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = true

  tags = local.common_tags
}

# Grants the Terraform execution identity permission to create the Key Vault secret.
resource "azurerm_role_assignment" "terraform_key_vault_administrator" {
  scope                = azurerm_key_vault.service.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  value        = var.database_administrator_password
  key_vault_id = azurerm_key_vault.service.id

  depends_on = [
    azurerm_role_assignment.terraform_key_vault_administrator
  ]
}

# A user-assigned identity can be created before the Container App.
resource "azurerm_user_assigned_identity" "container_app" {
  name                = "id-${local.resource_suffix}"
  location            = azurerm_resource_group.service.location
  resource_group_name = azurerm_resource_group.service.name
  tags                = local.common_tags
}

# Allows the Container App identity to read secrets from Key Vault.
resource "azurerm_role_assignment" "container_app_key_vault_secrets_user" {
  scope                = azurerm_key_vault.service.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

resource "azurerm_container_app" "service" {
  name                         = "ca-${local.resource_suffix}"
  container_app_environment_id = azurerm_container_app_environment.service.id
  resource_group_name          = azurerm_resource_group.service.name
  revision_mode                = "Single"

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.container_app.id
    ]
  }

  secret {
    name                = "database-password"
    identity            = azurerm_user_assigned_identity.container_app.id
    key_vault_secret_id = azurerm_key_vault_secret.database_password.versionless_id
  }

  template {
    min_replicas = var.minimum_replicas
    max_replicas = var.maximum_replicas

    container {
      name   = var.application_name
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.service.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.application.name
      }

      env {
        name  = "DB_USER_NAME"
        value = var.database_administrator_login
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "database-password"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 4000
        path      = "/health"
      }

      liveness_probe {
        transport = "HTTP"
        port      = 4000
        path      = "/health"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 4000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = local.common_tags

  depends_on = [
    azurerm_role_assignment.container_app_key_vault_secrets_user
  ]
}