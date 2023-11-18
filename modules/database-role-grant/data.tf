data "aws_secretsmanager_secret" "db" {
  name = "arn:aws:secretsmanager:us-east-1:551892827149:secret:/apps-factory-rds/rds/psql-5l0lFK"
}
data "aws_secretsmanager_secret_version" "credentials" {
  secret_id = data.aws_secretsmanager_secret.db.id
}
output "secret_value" {
  value = data.aws_secretsmanager_secret_version.credentials.secret_string
  sensitive = true
}
