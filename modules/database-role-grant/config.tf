terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
  }
}

provider "postgresql" {
  host            = "localhost"
  port            = "5433"
  username        = "jn_root_db_user"
  password        = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)["password"]
  sslmode         = "require"
  superuser       = false
  connect_timeout = 15
}