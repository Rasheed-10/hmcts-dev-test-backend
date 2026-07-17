variable "application_name" {
  description = "Name of the application."
  type        = string
  default     = "case-tracker"

  validation {
    condition     = length(var.application_name) >= 3
    error_message = "The application name must contain at least three characters."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "test", "staging", "production"], var.environment)
    error_message = "Environment must be development, test, staging or production."
  }
}

variable "location" {
  description = "Azure region in which resources will be deployed."
  type        = string
  default     = "uksouth"
}

variable "container_image" {
  description = "Fully qualified container image and immutable tag to deploy."
  type        = string
  default     = "ghcr.io/example/hmcts-dev-test-backend:replace-with-git-sha"
}

variable "database_name" {
  description = "Name of the PostgreSQL application database."
  type        = string
  default     = "devtest"
}

variable "database_administrator_login" {
  description = "Administrator username for PostgreSQL."
  type        = string
  default     = "caseadmin"
}

variable "database_administrator_password" {
  description = "PostgreSQL administrator password supplied securely by the deployment pipeline."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.database_administrator_password) >= 12
    error_message = "The database password must contain at least 12 characters."
  }
}

variable "postgresql_sku_name" {
  description = "Azure PostgreSQL Flexible Server compute SKU."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "minimum_replicas" {
  description = "Minimum number of Container App replicas."
  type        = number
  default     = 1
}

variable "maximum_replicas" {
  description = "Maximum number of Container App replicas."
  type        = number
  default     = 3

  validation {
    condition     = var.maximum_replicas >= var.minimum_replicas
    error_message = "Maximum replicas must be greater than or equal to minimum replicas."
  }
}

variable "tags" {
  description = "Tags applied to Azure resources."
  type        = map(string)

  default = {
    managed-by = "terraform"
    service    = "case-tracker"
    owner      = "hmcts"
  }
}