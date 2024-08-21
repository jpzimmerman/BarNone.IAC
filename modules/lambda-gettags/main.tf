resource "aws_lambda_function" "gettags_func" {
  filename      = "${path.module}/output/barnone-gettags-lambda.zip"
  function_name = "RDS_GetTags"
  role          = data.aws_iam_role.rds_lambda.arn
  handler       = "gettags.handler"
  runtime       = "python3.10"
  timeout       = 30
  vpc_config {
    subnet_ids         = [data.aws_subnet.barnone-private1-a.id, data.aws_subnet.barnone-private2-b.id]
    security_group_ids = ["sg-032b6998293ede047"]
  }
}

resource "aws_lambda_function_url" "gettags_url" {
  function_name      = aws_lambda_function.gettags_func.arn
  authorization_type = "NONE"
}