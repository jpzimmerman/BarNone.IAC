################################
##     Imported Resources     ##
################################
resource "aws_vpc" "barnone-vpc" {
  tags = {
    "Name" = "barnone-vpc"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "barnone-subnet-public1-a" {
  vpc_id                  = aws_vpc.barnone-vpc.id
  cidr_block              = "10.0.0.0/20"
  map_public_ip_on_launch = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    "Name" = "barnone-subnet-public1-us-east-1a"
  }
}

resource "aws_subnet" "barnone-subnet-public2-b" {
  vpc_id                  = aws_vpc.barnone-vpc.id
  cidr_block              = "10.0.16.0/20"
  map_public_ip_on_launch = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    "Name" = "barnone-subnet-public2-us-east-1b"
  }
}


###################################################
##    Security Groups, Inbound/Outbound Rules    ##
###################################################

resource "aws_security_group" "barnone-db" {
  vpc_id = aws_vpc.barnone-vpc.id

  ingress {

    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allopen_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allopen_cidr_block]
  }

  tags = {
    Name = "barnone-db"
  }

  depends_on = [aws_vpc.barnone-vpc]
}

############################
##  DB Instance(s)  ##
############################

resource "aws_db_subnet_group" "barnone-db-subnet-group" {
  name       = "barnone-db-subnet-group"
  subnet_ids = [aws_subnet.barnone-subnet-public1-a.id, aws_subnet.barnone-subnet-public2-b.id]

  tags = {
    Name = "Cocktails DB subnet group"
  }
}


resource "aws_db_instance" "cocktails" {
  engine                 = "mysql"
  db_name                = var.rds_db_name
  identifier             = var.rds_db_name
  allocated_storage      = 20
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "[SECRET]"
  password               = "[SECRET]"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = true
  storage_type           = "gp3"
  multi_az               = false
  vpc_security_group_ids = ["${aws_security_group.barnone-db.id}"]
  db_subnet_group_name   = aws_db_subnet_group.barnone-db-subnet-group.id
  apply_immediately      = true

  depends_on = [aws_db_subnet_group.barnone-db-subnet-group]
}
