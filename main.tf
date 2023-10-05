
resource "random_password" "rds_password" {
  length           = 16     # Specify the desired password length
  special          = true   # Include special characters in the password
  override_special = "_!@#" # Optional: Specify additional special characters
}

module "security_group" {
  source      = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git//"
  name        = "${var.identifier}-db"
  description = "PostgreSQL security group"
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within transit gateway attached vpc"
      cidr_blocks = var.cidr_blocks # we are in an private network
    },
  ]
}

module "secrets_manager" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git//"

  name                    = var.secret_name
  description             = "Credentials of PostgreSQL"
  recovery_window_in_days = 7
  create_policy           = false
  block_public_policy     = true
  secret_string = jsonencode({
    engine   = "postgresql",
    host     = module.postgresql.db_instance_address,
    username = module.postgresql.db_instance_username,
    password = random_password.rds_password.result
    port     = module.postgresql.db_instance_port
    database = module.postgresql.db_instance_name
  })

  tags = var.tags
}

module "postgresql" {
  source     = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git//"
  identifier = var.identifier

  engine               = "postgres"
  engine_version       = var.major_engine_version
  family               = "postgres${var.major_engine_version}" # DB parameter group
  major_engine_version = var.major_engine_version              # DB option group
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name                = var.db_name
  username               = var.username
  port                   = 5432
  password               = random_password.rds_password.result
  multi_az               = var.multi_az
  vpc_security_group_ids = [module.security_group.security_group_id]
  create_db_subnet_group = true
  subnet_ids             = var.subnet_ids

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true
  manage_master_user_password     = false

  backup_retention_period      = var.backup_retention_period
  skip_final_snapshot          = var.skip_final_snapshot
  deletion_protection          = var.deletion_protection
  performance_insights_enabled = var.performance_insights_enabled

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
}

module "route53_record" {
  source  = "git::github.com/terraform-aws-modules/terraform-aws-route53.git//modules/records"
  zone_id = var.route53_zone_zone_id
  records = [
    {
      name    = var.route53_db_record
      type    = "CNAME"
      ttl     = 60
      records = [module.postgresql.db_instance_address]
    }
  ]
}