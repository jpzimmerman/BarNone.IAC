resource "aws_vpc" "barnone_vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "barnone_vpc"
  }
}

###################################################
##    Security Groups, Inbound/Outbound Rules    ##
###################################################

resource "aws_default_security_group" "barnone-db" {
  vpc_id = aws_vpc.barnone_vpc.id

  ingress {

    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "barnone-db"
  }

  depends_on = [aws_vpc.barnone_vpc]
}


resource "aws_default_network_acl" "barnone-acl" {
  default_network_acl_id = aws_vpc.barnone_vpc.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}
#####################
##     Subnets     ##
#####################

resource "aws_subnet" "barnone-subnet-public1-us-east-1a" {
  vpc_id                                         = aws_vpc.barnone_vpc.id
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "us-east-1a"
  cidr_block                                     = "10.0.0.0/20"
  customer_owned_ipv4_pool                       = ""
  enable_dns64                                   = false
  enable_resource_name_dns_a_record_on_launch    = false
  enable_resource_name_dns_aaaa_record_on_launch = false
  ipv6_native                                    = false
  map_customer_owned_ip_on_launch                = false
  map_public_ip_on_launch                        = true
  outpost_arn                                    = ""
  private_dns_hostname_type_on_launch            = "ip-name"

  tags = {
    Name = "barnone-subnet-public1-us-east-1a"
  }

  depends_on = [aws_vpc.barnone_vpc]
}

resource "aws_subnet" "barnone-subnet-private1-us-east-1a" {
  vpc_id                                         = aws_vpc.barnone_vpc.id
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "us-east-1a"
  cidr_block                                     = "10.0.128.0/20"
  customer_owned_ipv4_pool                       = ""
  enable_dns64                                   = false
  enable_resource_name_dns_a_record_on_launch    = false
  enable_resource_name_dns_aaaa_record_on_launch = false
  ipv6_native                                    = false
  map_customer_owned_ip_on_launch                = false
  map_public_ip_on_launch                        = true
  outpost_arn                                    = ""
  private_dns_hostname_type_on_launch            = "ip-name"

  tags = {
    Name = "barnone-subnet-private1-us-east-1a"
  }
}

resource "aws_subnet" "barnone-subnet-public2-us-east-1b" {
  vpc_id                                         = aws_vpc.barnone_vpc.id
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "us-east-1b"
  cidr_block                                     = "10.0.16.0/20"
  customer_owned_ipv4_pool                       = ""
  enable_dns64                                   = false
  enable_resource_name_dns_a_record_on_launch    = false
  enable_resource_name_dns_aaaa_record_on_launch = false
  ipv6_native                                    = false
  map_customer_owned_ip_on_launch                = false
  map_public_ip_on_launch                        = true
  outpost_arn                                    = ""
  private_dns_hostname_type_on_launch            = "ip-name"

  tags = {
    Name = "barnone-subnet-public2-us-east-1b"
  }
}

resource "aws_subnet" "barnone-subnet-private2-us-east-1b" {
  vpc_id                                         = aws_vpc.barnone_vpc.id
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "us-east-1b"
  cidr_block                                     = "10.0.144.0/20"
  customer_owned_ipv4_pool                       = ""
  enable_dns64                                   = false
  enable_resource_name_dns_a_record_on_launch    = false
  enable_resource_name_dns_aaaa_record_on_launch = false
  ipv6_native                                    = false
  map_customer_owned_ip_on_launch                = false
  map_public_ip_on_launch                        = true
  outpost_arn                                    = ""
  private_dns_hostname_type_on_launch            = "ip-name"

  tags = {
    Name = "barnone-subnet-private2-us-east-1b"
  }
}

##########################
##  Internet Gateways   ##
##########################

resource "aws_internet_gateway" "barnone-igw" {
  vpc_id = aws_vpc.barnone_vpc.id

  tags = {
    Name = "barnone-igw"
  }
}

####################
## Routing Tables ##
####################

resource "aws_default_route_table" "barnone-rtb-public" {
  default_route_table_id = aws_vpc.barnone_vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.barnone-igw.id
  }

  tags = {
    Name = "barnone-rtb-public"
  }

  depends_on = [aws_internet_gateway.barnone-igw]
}

resource "aws_route" "internet-route" {
  route_table_id         = aws_vpc.barnone_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.barnone-igw.id
}

## Route Table associations
resource "aws_route_table_association" "barnone-public-association1" {
  subnet_id      = aws_subnet.barnone-subnet-public1-us-east-1a.id
  route_table_id = aws_vpc.barnone_vpc.default_route_table_id
}

resource "aws_route_table_association" "barnone-public-association2" {
  subnet_id      = aws_subnet.barnone-subnet-public2-us-east-1b.id
  route_table_id = aws_vpc.barnone_vpc.default_route_table_id
}

resource "aws_route_table_association" "barnone-private-association1" {
  subnet_id      = aws_subnet.barnone-subnet-private1-us-east-1a.id
  route_table_id = aws_vpc.barnone_vpc.default_route_table_id
}

resource "aws_route_table_association" "barnone-private-association2" {
  subnet_id      = aws_subnet.barnone-subnet-private2-us-east-1b.id
  route_table_id = aws_vpc.barnone_vpc.default_route_table_id
}


############################
##  DB Instance(s)  ##
############################

resource "aws_db_subnet_group" "barnone-db-subnet-group" {
  name       = "barnone-db-subnet-group"
  subnet_ids = [aws_subnet.barnone-subnet-public1-us-east-1a.id, aws_subnet.barnone-subnet-public2-us-east-1b.id]

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
  vpc_security_group_ids = ["${aws_default_security_group.barnone-db.id}"]
  db_subnet_group_name   = aws_db_subnet_group.barnone-db-subnet-group.id
  apply_immediately      = true

  depends_on = [aws_internet_gateway.barnone-igw, aws_db_subnet_group.barnone-db-subnet-group]
}
