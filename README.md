# terraform-module-rds-postgresql

```
module "terraform-module-rds-postgresql" {
  source = "../terraform-module-rds-postgresql"
  private_subnets              = module.vpc.private_subnets
  vpc_id                       = module.vpc.vpc_id
  cidr_blocks                  = "10.0.0.0/8"
  subnet_ids                   = module.vpc.private_subnets
  route53_zone_zone_id         = lookup(module.zone.route53_zone_zone_id)
  secret_name                  = "/shared-services/apps-db/postgresql"
  env                          = "shared-services"
  major_engine_version         = "14"
  instance_class               = "db.t4g.micro"
  allocated_storage            = 20
  max_allocated_storage        = 40
  db_name                      = "my_custom_db_name"
  username                     = "my_custom_db_username"
  multi_az                     = false
  backup_retention_period      = 5
  skip_final_snapshot          = true
  deletion_protection          = false
  performance_insights_enabled = false
  identifier                   = "my-rds-id"
  tags = {
    Environment = "shared-services"
    Project     = "MyProject"
  }
}
```
