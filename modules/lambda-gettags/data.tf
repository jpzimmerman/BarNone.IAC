data "aws_vpc" "barnone" {
  filter {
    name   = "tag:Name"
    values = ["barnone-vpc"]
  }
}

data "aws_subnet" "barnone-private1-a" {
  vpc_id = data.aws_vpc.barnone.id
  filter {
    name   = "tag:Name"
    values = ["barnone-subnet-private1-us-east-1a"]
  }
}

data "aws_subnet" "barnone-private2-b" {
  vpc_id = data.aws_vpc.barnone.id
  filter {
    name   = "tag:Name"
    values = ["barnone-subnet-private2-us-east-1b"]
  }
}

data "aws_iam_role" "rds_lambda" {
  name = "lambda_function_role"
}

data "archive_file" "lambda_func_src" {
  type        = "zip"
  source_dir  = "${path.module}/src/"
  output_path = "${path.module}/output/barnone-gettags-lambda.zip"
}