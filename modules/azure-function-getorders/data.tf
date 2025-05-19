data "azurerm_resource_group" "sample_resource_group" {
  name = "sample_resource_group"
}

data "azurerm_service_plan" "sample_plan" {
  name                = "sample-plan"
  resource_group_name = "sample_resource_group"
}

data "archive_file" "getorders_code_package" {
  type        = "zip"
  source_dir  = "${path.module}\\src\\GetOrders\\GetOrders\\bin\\Debug\\net9.0"
  output_path = "${path.module}\\src\\GetOrders\\GetOrders\\bin\\Debug\\net9.0\\output.zip"
}