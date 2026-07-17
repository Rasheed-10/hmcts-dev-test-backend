locals {
  resource_suffix = "${var.application_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      environment = var.environment
      application = var.application_name
    }
  )
}