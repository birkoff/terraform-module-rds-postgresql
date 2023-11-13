data "aws_caller_identity" "current" {}

locals {
  default_identifier = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  identifiers        = compact(concat(var.share_with, local.default_identifier))
}


resource "random_password" "rds_password" {
  length           = 16     # Specify the desired password length
  special          = true   # Include special characters in the password
  override_special = "_!@#" # Optional: Specify additional special characters
}

module "security_group" {
  source      = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git//"
  name        = "${var.identifier}-db"
  description = "RDS Database security group"
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = var.port
      to_port     = var.port
      protocol    = "tcp"
      description = "RDS Database access from within transit gateway attached vpc"
      cidr_blocks = var.cidr_blocks # we are in an private network
    },
  ]
}
variable "kms_key_id" {
  type = string
  default = ""
}
module "secrets_manager" {
  depends_on              = [module.rds, random_password.rds_password]
  source                  = "git::https://github.com/terraform-aws-modules/terraform-aws-secrets-manager.git//"
  name                    = var.secret_name
  description             = "Credentials of RDS Database"
  recovery_window_in_days = 7
  # Policy
  create_policy       = length(var.share_with) > 0 ? true : false
  block_public_policy = true
  kms_key_id          = var.kms_key_id != "" ? var.kms_key_id : null
  policy_statements = {
    read = {
      sid = "AllowAccountRead"
      principals = [{
        type        = "AWS"
        identifiers = local.identifiers #["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::225725557140:root", "arn:aws:iam::443207202695:root"]
      }]
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetRandomPassword",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:ListSecretVersionIds",
        "secretsmanager:ListSecrets"
      ]
      resources = ["*"]
    }
  }

  secret_string = jsonencode({
    engine   = "postgresql",
    host     = module.rds.db_instance_address,
    dns_record = "${var.db_record}.${var.dns_zone_name}",
    username = module.rds.db_instance_username,
    password = random_password.rds_password.result,
    port     = module.rds.db_instance_port,
    database = module.rds.db_instance_name
  })
}

module "rds" {
  depends_on = [random_password.rds_password, module.security_group]
  source     = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git//"
  identifier = var.identifier

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_RDS Database.html#RDS Database.Concepts
  engine               = var.engine
  engine_version       = var.major_engine_version
  family               = "${var.engine}${var.major_engine_version}" # DB parameter group
  major_engine_version = var.major_engine_version                   # DB option group
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name                = var.db_name
  username               = var.username
  port                   = var.port
  password               = random_password.rds_password.result
  multi_az               = var.multi_az
  vpc_security_group_ids = [module.security_group.security_group_id]
  create_db_subnet_group = true
  subnet_ids             = var.subnet_ids

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
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

variable "dns_zone_id" {
  type = string
  default = null
}
variable "dns_zone_name" {
  type = string
  default = null
}
module "route53_record" {
  depends_on = [module.rds]
  source     = "git::github.com/terraform-aws-modules/terraform-aws-route53.git//modules/records"
  zone_id    = try(var.dns_zone_id, null)
  # zone_name    = try(var.dns_zone_name, null)
  # create     = var.dns_zone_id != "" ? true : false
  private_zone = true
  records = [
    {
      name    = var.db_record
      type    = "CNAME"
      ttl     = 300
      records = [module.rds.db_instance_address]
    }
  ]
}
