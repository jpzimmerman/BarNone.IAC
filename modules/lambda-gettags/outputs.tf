output "gettags_url" {
  description = "'Get Menu Items' function URL"
  value       = aws_lambda_function_url.gettags_url.function_url
}