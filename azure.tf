resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.azure_deployment_domain_name}"
  location = "East US 2"
}

resource "azurerm_cognitive_account" "openai" {
  name                  = var.azure_deployment_domain_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "OpenAI"
  custom_subdomain_name = var.azure_deployment_domain_name
  sku_name              = "S0"
  lifecycle {
    ignore_changes = [
      tags["FAMIS Account"]
    ]
  }
}

resource "azurerm_cognitive_deployment" "deployments" {
  for_each = var.azure_openai_models

  name                   = each.value.model_name
  cognitive_account_id   = azurerm_cognitive_account.openai.id
  version_upgrade_option = "OnceNewDefaultVersionAvailable"

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.version
  }

  sku {
    name = each.value.sku
  }
}