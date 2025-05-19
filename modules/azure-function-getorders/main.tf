resource "azurerm_service_plan" "sample_plan" {
  name                = "sample-plan"
  resource_group_name = data.azurerm_resource_group.sample_resource_group.name
  location            = data.azurerm_resource_group.sample_resource_group.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "barnone_web_app" {
  name                = "barnone-web-app"
  resource_group_name = data.azurerm_resource_group.sample_resource_group.name
  location            = azurerm_service_plan.sample_plan.location
  service_plan_id     = azurerm_service_plan.sample_plan.id

  site_config {
    always_on = false
    application_stack {
      dotnet_version = "9.0"
    }
  }
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
  service_plan_id            = data.azurerm_service_plan.sample_plan.id
  storage_account_name       = azurerm_storage_account.barnonesa.name
  storage_account_access_key = azurerm_storage_account.barnonesa.primary_access_key
  zip_deploy_file            = data.archive_file.getorders_code_package.output_path

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = 1
  }

  site_config {
    cors {
      allowed_origins = ["GET"]
    }
  }
}