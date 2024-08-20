resource "aws_security_group" "barnone-sg-lambdas" {
  name        = "barnone-sg-lambdas"
  vpc_id      = data.aws_vpc.barnone.id
  description = "Security group for Lambdas"

  egress {
    description = "Egress rule for Lambdas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "barnone-sg-lambdas"
  }
}

resource "aws_security_group" "barnone-sg-rdsproxy" {
  name        = "barnone-sg-rdsproxy"
  vpc_id      = data.aws_vpc.barnone.id
  description = "Security group facilitating connection Lambdas and RDS proxy"

  ingress {
    description = "Ingress rule for MySQL DB"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Egress rule for Lambdas"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "barnone-sg-rdsproxy"
  }
}

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

resource "aws_lambda_function" "getmenuitems_func" {
  filename      = "${path.module}/src/barnone-getmenuitems-lambda.zip"
  function_name = "RDS_GetMenuItems"
  role          = aws_iam_role.rds_lambda.arn
  handler       = "Lambda_GetMenuItems::Lambda_GetMenuItems.Function::FunctionHandler"
  runtime       = "dotnet6"
  timeout       = 30
  vpc_config {
    subnet_ids         = [data.aws_subnet.barnone-private1-a.id, data.aws_subnet.barnone-private2-b.id]
    security_group_ids = ["sg-0cd7f99cce851f292"]
  }

  depends_on = [aws_iam_role_policy_attachment.rds_lambda_attachment]
}

resource "aws_lambda_function_url" "get_menu_items_url" {
  function_name      = aws_lambda_function.getmenuitems_func.arn
  authorization_type = "NONE"
}