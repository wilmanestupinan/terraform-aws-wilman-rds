resource "aws_rds_cluster" "cluster" {
  cluster_identifier        = "${var.system_name}-cluster"
  engine                    = "aurora-mysql"
  engine_version            = "5.7.mysql_aurora.2.07.1"
  database_name             = aws_ssm_parameter.dbname.value
  master_username           = aws_ssm_parameter.dbuser.value
  master_password           = aws_ssm_parameter.dbpassword.value
  db_subnet_group_name      = aws_db_subnet_group.dbsubnet.id
  engine_mode               = "serverless"
  vpc_security_group_ids    = [aws_security_group.rds_secgrp.id]
  skip_final_snapshot       = var.final_snapshot_identifier == null
  final_snapshot_identifier = var.final_snapshot_identifier

  scaling_configuration {
    min_capacity = 1
    max_capacity = 2
  }
}

resource "aws_ssm_parameter" "dbname" {
  name  = "/app/${var.system_name}/DATABASE_NAME"
  type  = "String"
  value = var.database_name
}

resource "aws_ssm_parameter" "dbuser" {
  name  = "/app/${var.system_name}/DATABASE_MASTER_USERNAME"
  type  = "String"
  value = var.database_master_username
}

resource "aws_ssm_parameter" "dbpassword" {
  name  = "/app/${var.system_name}/DATABASE_MASTER_PASSWORD"
  type  = "SecureString"
  value = random_password.password.result
}

resource "aws_ssm_parameter" "dbhost" {
  name  = "/app/${var.system_name}/DATABASE_HOST"
  type  = "String"
  value = aws_rds_cluster.cluster.endpoint
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "dbsubnet" {
  name        = "${var.system_name}-cluster-subnet"
  description = "Aurora ${var.system_name} cluster db subnet group"
  subnet_ids  = data.aws_subnet_ids.subnets.ids
}

resource "aws_security_group" "rds_secgrp" {
  name        = "${var.system_name} rds access"
  description = "RDS secgroup"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "VPC bound"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }
}

resource "aws_default_vpc" "default" {

}
