output "get_menu_items_url" {
  description = "'Get Menu Items' function URL"
  value       = aws_lambda_function_url.get_menu_items_url.function_url
}