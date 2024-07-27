data "aws_vpc" "barnone" {
  filter {
    name   = "tag:Name"
    values = ["barnone-vpc"]
  }
}

data "aws_subnet" "barnone-public1-a" {
  vpc_id = data.aws_vpc.barnone.id
  filter {
    name   = "tag:Name"
    values = ["barnone-subnet-public1-us-east-1a"]
  }
}

data "aws_subnet" "barnone-public2-b" {
  vpc_id = data.aws_vpc.barnone.id
  filter {
    name   = "tag:Name"
    values = ["barnone-subnet-public2-us-east-1b"]
  }
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_task_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}