output "gettags_url" {
  description = "'Add Inventory Item' function URL"
  value       = aws_lambda_function_url.additem_url.function_url
}