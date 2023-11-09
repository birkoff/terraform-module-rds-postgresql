variable "subnet_ids" {
  default = []
  type    = list(string)
}

variable "env" {
  default = ""
}
variable "vpc_id" {
  default = ""
}
variable "cidr_blocks" {
  default = ""
}

variable "route53_zone_id" {
  default = ""
}

variable "identifier" {
  default = ""
}
variable "major_engine_version" {
  default = "14"
}
variable "instance_class" {
  default = "db.t4g.micro"
}
variable "allocated_storage" {
  default = 20
}
variable "max_allocated_storage" {
  default = 40
}
variable "db_name" {
  default = ""
}
variable "username" {
  default = ""
}
variable "port" {
  default = "5432"
}
variable "multi_az" {
  default = false
}
variable "backup_retention_period" {
  default = 5
}
variable "skip_final_snapshot" {
  default = true
}
variable "deletion_protection" {
  default = false
}
variable "performance_insights_enabled" {
  default = false
}

variable "tags" {
  type = any
}

variable "secret_name" {
  type = string
}
variable "db_record" {
  default = "db"
}
variable "share_with" {
  type = list(string)
}

variable "engine" {
  type    = string
  default = "postgres"
}

variable "enabled_cloudwatch_logs_exports" {
  type = list(string)
}
#variable "kms_key_id" {
#  type = string
#}
