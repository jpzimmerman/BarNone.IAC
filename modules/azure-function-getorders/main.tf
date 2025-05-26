resource "azurerm_service_plan" "getorders_service_plan" {
  name                = "getorders-service-plan"
  resource_group_name = data.azurerm_resource_group.sample_resource_group.name
  location            = data.azurerm_resource_group.sample_resource_group.location
  sku_name            = "B1"
  os_type             = "Linux"
}
resource "azurerm_storage_account" "barnonesa" {
  name                     = "getorderssa"
  resource_group_name      = data.azurerm_resource_group.sample_resource_group.name
  location                 = data.azurerm_resource_group.sample_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_function_app" "getorders" {
  name                       = "barnonegetorders"
  location                   = data.azurerm_resource_group.sample_resource_group.location
  resource_group_name        = data.azurerm_resource_group.sample_resource_group.name
  service_plan_id            = azurerm_service_plan.getorders_service_plan.id
  storage_account_name       = azurerm_storage_account.barnonesa.name
  storage_account_access_key = azurerm_storage_account.barnonesa.primary_access_key
  zip_deploy_file            = data.archive_file.getorders_code_package.output_path

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE      = 1
    FUNCTIONS_WORKER_RUNTIME      = "dotnet"
    FUNCTIONS_INPROC_NET8_ENABLED = 1
    DB_CONNECTION                 = "SECRET"

  }

  site_config {
    cors {
      allowed_origins = ["GET"]
    }

    always_on           = true
    minimum_tls_version = "1.2"

    application_stack {
      dotnet_version = "8.0"
    }
  }
}