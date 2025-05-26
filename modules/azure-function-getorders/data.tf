data "azurerm_resource_group" "sample_resource_group" {
  name = "sample_resource_group"
}

data "archive_file" "getorders_code_package" {
  type        = "zip"
  source_dir  = "${path.module}\\src\\GetOrders\\GetOrders\\bin\\Debug\\net8.0"
  output_path = "${path.module}\\src\\GetOrders\\GetOrders\\bin\\Debug\\net8.0\\output.zip"
}