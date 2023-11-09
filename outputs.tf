output "db_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "route53_db_endpoint_internal" {
  value = module.route53_record.route53_record_name
}

output "db_secret_arn" {
  value = module.secrets_manager.secret_arn
}