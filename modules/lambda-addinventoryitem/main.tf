resource "aws_lambda_function" "additem_func" {
  filename      = "${path.module}/output/barnone-additem-lambda.zip"
  function_name = "BarNone_AddInventoryItem"
  role          = data.aws_iam_role.rds_lambda.arn
  handler       = "additem.handler"
  runtime       = "python3.10"
  timeout       = 30
  reserved_concurrent_executions = 20

  tracing_config {
    mode = "Active"
  }
  
  vpc_config {
    subnet_ids         = [data.aws_subnet.barnone-private1-a.id, data.aws_subnet.barnone-private2-b.id]
    security_group_ids = ["sg-032b6998293ede047"]
  }
}

resource "aws_lambda_function_url" "additem_url" {
  function_name      = aws_lambda_function.additem_func.arn
  authorization_type = "AWS_IAM"

  cors {
    allow_methods = ["POST"]
  }
}