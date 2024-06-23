resource "aws_vpc" "barnone-vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "barnone-vpc"
  }
}

###################################################
##    Security Groups, Inbound/Outbound Rules    ##
###################################################

resource "aws_default_security_group" "barnone-db" {
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


resource "aws_default_network_acl" "barnone-acl" {
  default_network_acl_id = aws_vpc.barnone-vpc.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.allopen_cidr_block
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.allopen_cidr_block
    from_port  = 0
    to_port    = 0
  }
}
#####################
##     Subnets     ##
#####################

resource "aws_subnet" "barnone-subnet-public1-a" {
  vpc_id                                         = aws_vpc.barnone-vpc.id
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "${data.aws_region.current_region.name}a"
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
    Name = "barnone-subnet-public1-a"
  }

  depends_on = [aws_vpc.barnone-vpc]
}

resource "aws_subnet" "barnone-subnet-private1-a" {
  vpc_id                                         = aws_vpc.barnone-vpc.id
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "${data.aws_region.current_region.name}a"
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
    Name = "barnone-subnet-private1-${data.aws_region.current_region.name}a"
  }
}

resource "aws_subnet" "barnone-subnet-public2-b" {
  vpc_id                                         = aws_vpc.barnone-vpc.id
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "${data.aws_region.current_region.name}b"
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
    Name = "barnone-subnet-public2-${data.aws_region.current_region.name}b"
  }
}

resource "aws_subnet" "barnone-subnet-private2-b" {
  vpc_id                                         = aws_vpc.barnone-vpc.id
  assign_ipv6_address_on_creation                = false
  availability_zone                              = "${data.aws_region.current_region.name}b"
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
    Name = "barnone-subnet-private2-${data.aws_region.current_region.name}b"
  }
}

##########################
##  Internet Gateways   ##
##########################

resource "aws_internet_gateway" "barnone-igw" {
  vpc_id = aws_vpc.barnone-vpc.id

  tags = {
    Name = "barnone-igw"
  }
}

####################
## Routing Tables ##
####################

resource "aws_default_route_table" "barnone-rtb-public" {
  default_route_table_id = aws_vpc.barnone-vpc.default_route_table_id
  route {
    cidr_block = var.allopen_cidr_block
    gateway_id = aws_internet_gateway.barnone-igw.id
  }

  tags = {
    Name = "barnone-rtb-public"
  }

  depends_on = [aws_internet_gateway.barnone-igw]
}

resource "aws_route" "internet-route" {
  route_table_id         = aws_vpc.barnone-vpc.main_route_table_id
  destination_cidr_block = var.allopen_cidr_block
  gateway_id             = aws_internet_gateway.barnone-igw.id
}

## Route Table associations
resource "aws_route_table_association" "barnone-public-association1" {
  subnet_id      = aws_subnet.barnone-subnet-public1-a.id
  route_table_id = aws_vpc.barnone-vpc.default_route_table_id
}

resource "aws_route_table_association" "barnone-public-association2" {
  subnet_id      = aws_subnet.barnone-subnet-public2-b.id
  route_table_id = aws_vpc.barnone-vpc.default_route_table_id
}

resource "aws_route_table_association" "barnone-private-association1" {
  subnet_id      = aws_subnet.barnone-subnet-private1-a.id
  route_table_id = aws_vpc.barnone-vpc.default_route_table_id
}

resource "aws_route_table_association" "barnone-private-association2" {
  subnet_id      = aws_subnet.barnone-subnet-private2-b.id
  route_table_id = aws_vpc.barnone-vpc.default_route_table_id
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
  vpc_security_group_ids = ["${aws_default_security_group.barnone-db.id}"]
  db_subnet_group_name   = aws_db_subnet_group.barnone-db-subnet-group.id
  apply_immediately      = true

  depends_on = [aws_internet_gateway.barnone-igw, aws_db_subnet_group.barnone-db-subnet-group]
}
