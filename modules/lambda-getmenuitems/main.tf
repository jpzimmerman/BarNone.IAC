resource "aws_lambda_function" "getmenuitems_func" {
  filename      = "${path.module}/src/barnone-getmenuitems-lambda.zip"
  function_name = "RDS_GetMenuItems"
  role          = data.aws_iam_role.rds_lambda.arn
  handler       = "Lambda_GetMenuItems::Lambda_GetMenuItems.Function::FunctionHandler"
  runtime       = "dotnet6"
  timeout       = 30
  tracing_config {
    mode = "PassThrough"
  }
  vpc_config {
    subnet_ids         = [data.aws_subnet.barnone-private1-a.id, data.aws_subnet.barnone-private2-b.id]
    security_group_ids = ["sg-032b6998293ede047"]
  }
}

resource "aws_lambda_function_url" "get_menu_items_url" {
  function_name      = aws_lambda_function.getmenuitems_func.arn
  authorization_type = "NONE"

  cors {
    allow_methods = ["GET"]
  }
}