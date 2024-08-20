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

data "aws_db_instance" "cocktails-db" {
  db_instance_identifier = "cocktails"
}

data "template_file" "policy_template" {
  template = file("json/policy.tpl")

  vars = {
    db-instance-arn = "arn:aws:rds-db:us-east-1:169002939622:dbuser:${data.aws_db_instance.cocktails-db.resource_id}/dbuser"
  }
}

data "archive_file" "lambda_func_src" {
  type        = "zip"
  source_dir  = "${path.module}/bin/"
  output_path = "${path.module}/src/barnone-getmenuitems-lambda.zip"
}