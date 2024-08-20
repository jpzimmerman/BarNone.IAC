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

resource "aws_default_security_group" "barnone-sg-default" {
  vpc_id = aws_vpc.barnone-vpc.id

  ingress {

    from_port   = 80
    to_port     = 80
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
    Name = "barnone-sg-default"
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
    Name = "barnone-subnet-public1-${data.aws_region.current_region.name}a"
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
  map_public_ip_on_launch                        = false
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
  map_public_ip_on_launch                        = false
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

#################################
##   NAT Gateway, Elastic IP   ##
#################################

resource "aws_eip" "barnone-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.barnone-igw]
}

resource "aws_nat_gateway" "barnone-nat" {
  allocation_id = aws_eip.barnone-eip.id
  subnet_id     = aws_subnet.barnone-subnet-public1-a.id
  depends_on    = [aws_internet_gateway.barnone-igw]
  tags = {
    Name = "barnone-nat"
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

resource "aws_route_table" "barnone-rtb-private" {
  vpc_id = aws_vpc.barnone-vpc.id

  tags = {
    Name = "barnone-private-route-table"
  }
}

resource "aws_route" "internet-route" {
  route_table_id         = aws_vpc.barnone-vpc.main_route_table_id
  destination_cidr_block = var.allopen_cidr_block
  gateway_id             = aws_internet_gateway.barnone-igw.id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.barnone-rtb-private.id
  destination_cidr_block = var.allopen_cidr_block
  nat_gateway_id         = aws_nat_gateway.barnone-nat.id
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
  route_table_id = aws_route_table.barnone-rtb-private.id
}

resource "aws_route_table_association" "barnone-private-association2" {
  subnet_id      = aws_subnet.barnone-subnet-private2-b.id
  route_table_id = aws_route_table.barnone-rtb-private.id
}
