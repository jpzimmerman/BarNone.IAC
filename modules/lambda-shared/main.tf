resource "aws_iam_role" "rds_lambda" {
  name               = "lambda_function_role"
  assume_role_policy = file("json/role.json")
}

resource "aws_iam_policy" "rds_lambda" {
  name        = "rds_lambda"
  path        = "/"
  description = "AWS IAM Policy for AWS Lambda role"
  policy      = data.template_file.policy_template.rendered
}

resource "aws_iam_role_policy_attachment" "rds_lambda_attachment" {
  role = aws_iam_role.rds_lambda.name
  policy_arn = aws_iam_policy.rds_lambda.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpcaccess_attachment" {
  role       = aws_iam_role.rds_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}