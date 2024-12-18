# 使用する Aurora DB のエンジン、バージョン情報を定義
locals {
  # master_username = "tatsumi-tax"
  engine = "aurora-postgresql"
  # pgvectorを使用するには15.2以上のRDS PostgreSQLが必要
  # engine_version  = "15.0.postgresql_aurora.15.4"
  engine_version = "15.4"
  # instance_class  = "db.t4g.medium"
  instance_class = "db.serverless"
  # database_name   = "tax-rag"
}

# RDS
resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.service_name}-${var.env}-cluster"

  database_name   = var.database_name
  master_username = var.db_master_user
  # master_username                 = data.aws_ssm_parameter.list["PGVECTOR_USER"].value
  # master_password                 = random_password.this.result
  # master_password                 = data.aws_ssm_parameter.list["PGVECTOR_PASSWORD"].value
  manage_master_user_password     = true # secret managerを使用する
  availability_zones              = var.azs
  port                            = 5432
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_subnet_group_name            = var.db_subnet_group_name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.id
  engine                          = local.engine
  engine_mode                     = "provisioned"
  engine_version                  = local.engine_version
  final_snapshot_identifier       = "${var.service_name}-${var.env}-cluster-final-snapshot"
  skip_final_snapshot             = true
  apply_immediately               = true
  enable_http_endpoint            = true # Data api is enable

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }

  tags = {
    Name        = "${var.database_name}-${var.env}-cluster"
    Terraform   = "true"
    Environment = var.env
  }

  lifecycle {
    ignore_changes = [
      availability_zones,
    ]
  }

}

resource "aws_rds_cluster_instance" "this" {
  count              = 1
  identifier         = "${var.service_name}-${var.env}-${count.index}"
  engine             = local.engine
  engine_version     = local.engine_version
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = local.instance_class

  tags = {
    Name        = "${var.service_name}-${var.env}-${count.index}"
    Terraform   = "true"
    Environment = var.env
  }
}

# master_username のパスワードを自動生成
# resource "random_password" "this" {
#   length           = 12
#   special          = true
#   override_special = "!#&,:;_"

#   lifecycle {
#     ignore_changes = [
#       override_special
#     ]
#   }
# }


resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.service_name}-${var.env}-rds-cluster-parameter-group"
  family = "aurora-postgresql15"

  parameter {
    name  = "timezone"
    value = "Asia/Tokyo"
  }
}

# # Secrets ManagerにAuroraの認証情報を保存
# resource "aws_secretsmanager_secret" "aurora_secret" {
#   name = "aurora-db-credentials"
# }

# # シークレットのバージョン作成
# resource "aws_secretsmanager_secret_version" "aurora_secret_version" {
#   secret_id     = aws_secretsmanager_secret.aurora_secret.id
#   secret_string = jsonencode({
#     username = data.aws_ssm_parameter.list["PGVECTOR_USER"].value
#     password = data.aws_ssm_parameter.list["PGVECTOR_PASSWORD"].value
#     engine   = "aurora-mysql"
#     host     = aws_rds_cluster.aurora_cluster.endpoint
#     port     = "3306"
#     dbname   = "knowledge_base"
#   })
# }


# Security Group
resource "aws_security_group" "this" {
  name   = "${var.service_name}-${var.env}-rds-sg"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service_name}-${var.env}-rds-sg"
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_security_group_rule" "this" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = var.access_allow_cidr_blocks
  security_group_id = aws_security_group.this.id
}


# 各種パラメータを AWS Systems Manager Parameter Store へ保存
# resource "aws_ssm_parameter" "master_username" {
#   name  = "${var.service_name}/${var.env}/rds/master_username"
#   type  = "SecureString"
#   value = aws_rds_cluster.this.master_username

#   tags = {
#     Terraform   = "true"
#     environment = var.env
#   }
# }

# resource "aws_ssm_parameter" "master_password" {
#   name  = "${var.service_name}/${var.env}/rds/master_password"
#   type  = "SecureString"
#   value = aws_rds_cluster.this.master_password

#   tags = {
#     Terraform   = "true"
#     environment = var.env
#   }
# }

# resource "aws_ssm_parameter" "cluster_endpoint" {
#   name = "/tatsumi/tax_rag/stg/api/pgvector_host"
#   # name  = "${var.service_name}/${var.env}/rds/endpoint_w"
#   type  = "SecureString"
#   value = aws_rds_cluster.this.endpoint
#   overwrite = true

#   tags = {
#     Terraform   = "true"
#     environment = var.env
#   }
# }

# resource "aws_ssm_parameter" "cluster_reader_endpoint" {
#   name = "/tatsumi/tax_rag/stg/api/pgvector_ro_host"
#   # name  = "${var.service_name}/${var.env}/rds/endpoint_r"
#   type  = "SecureString"
#   value = aws_rds_cluster.this.reader_endpoint

#   tags = {
#     Terraform   = "true"
#     environment = var.env
#   }
# }