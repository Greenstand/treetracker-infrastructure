resource "postgresql_schema" "microservice_schema" {
  name  = var.schema
  owner = "doadmin"
}

resource "random_password" "s_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "service_user" {
  name     = "s_${var.schema}"
  login    = true
  password = random_password.s_password.result
}


resource "postgresql_grant" "wallet-microservice-user-usage" {
  database    = "treetracker"
  role        = "s_${var.schema}"
  schema      = "wallet"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "wallet-microservice-user" {
  database    = "treetracker"
  role        = "s_${var.schema}"
  schema      = var.schema
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}

resource "random_password" "m_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "migration_user" {
  name     = "m_${var.schema}"
  login    = true
  password = random_password.m_password.result
}


resource "postgresql_grant" "wallet-microservice-migration-executer" {
  database    = "treetracker"
  role        = "m_${var.schema}"
  schema      = var.schema
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

