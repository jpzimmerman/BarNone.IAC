data "aws_vpc" "barnone" {
  filter {
    name   = "tag:Name"
    values = ["barnone-vpc"]
  }
}

data "aws_security_group" "default_sg" {
  filter {
    name   = "tag:Name"
    values = ["barnone-sg-default"]
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