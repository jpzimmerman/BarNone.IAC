###################################################
##    Security Groups, Inbound/Outbound Rules    ##
###################################################

resource "aws_security_group" "barnone-db" {
  vpc_id      = data.aws_vpc.barnone.id
  description = "Security group facilitating connection between VPC and DB"

  ingress {
    description     = "Ingress rule for MySQL DB"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_security_group.default_sg.id]
  }

  tags = {
    Name = "barnone-db"
  }
}

############################
##  DB Instance(s)  ##
############################

resource "aws_db_subnet_group" "barnone-db" {
  name       = "barnone-db"
  subnet_ids = [data.aws_subnet.barnone-private1-a.id, data.aws_subnet.barnone-private2-b.id]

  tags = {
    Name = "Cocktails DB subnet group"
  }
}


resource "aws_db_instance" "cocktails" {
  engine                              = "mysql"
  db_name                             = var.rds_db_name
  identifier                          = var.rds_db_name
  allocated_storage                   = 20
  engine_version                      = "8.0"
  instance_class                      = "db.t3.micro"
  username                            = "[SECRET]"
  password                            = "[SECRET]"
  parameter_group_name                = "default.mysql8.0"
  performance_insights_enabled        = false
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  publicly_accessible                 = false
  storage_type                        = "gp2"
  auto_minor_version_upgrade          = true
  vpc_security_group_ids              = [aws_security_group.barnone-db.id]
  db_subnet_group_name                = aws_db_subnet_group.barnone-db.id
  apply_immediately                   = true

  depends_on = [aws_db_subnet_group.barnone-db]
}

resource "null_resource" "db_setup" {

  provisioner "local-exec" {

    command = "mysql -h ${aws_db_instance.cocktails.address} -P 3306 -p ${aws_db_instance.cocktails.username} -f ./cocktail-db-init.sql"

    environment = {
      PASSWORD = "${aws_db_instance.cocktails.password}"
    }
  }
}
