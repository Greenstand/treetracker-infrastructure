resource "postgresql_schema" "microservice_schema" {
  name  = var.schema
  owner = "doadmin"

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_password" "s_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "service_user" {
  name        = "s_${var.schema}"
  login       = true
  password    = random_password.s_password.result
  search_path = [var.schema, "public"]
}

resource "postgresql_grant" "microservice-user-usage" {
  database    = var.database
  role        = "s_${var.schema}"
  schema      = var.schema
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_default_privileges" "microservice-user-default" {
  database = var.database
  role     = "s_${var.schema}"
  schema   = var.schema

  owner       = "m_${var.schema}"
  object_type = "table"
  privileges  = var.service_user_table_grants
}

resource "postgresql_default_privileges" "microservice-user-default-sequence" {
  database = var.database
  role     = "s_${var.schema}"
  schema   = var.schema

  owner       = "m_${var.schema}"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}

resource "postgresql_grant" "microservice-user" {
  database    = var.database
  role        = "s_${var.schema}"
  schema      = var.schema
  object_type = "table"
  privileges  = var.service_user_table_grants
}

resource "postgresql_grant" "microservice-user-sequence" {
  database    = var.database
  role        = "s_${var.schema}"
  schema      = var.schema
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}

resource "random_password" "m_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "migration_user" {
  name        = "m_${var.schema}"
  login       = true
  password    = random_password.m_password.result
  search_path = [var.schema, "public"]
}


resource "postgresql_grant" "microservice-migration-executer" {
  database    = var.database
  role        = "m_${var.schema}"
  schema      = var.schema
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}


resource "postgresql_grant" "microservice-migration-executer-tables" {
  database    = var.database
  role        = "m_${var.schema}"
  schema      = var.schema
  object_type = "table"
  privileges  = ["INSERT", "SELECT", "REFERENCES", "UPDATE", "DELETE"]
}

resource "postgresql_grant" "microservice-migration-executor-sequence" {
  database    = var.database
  role        = "m_${var.schema}"
  schema      = var.schema
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}


resource "postgresql_grant" "readonlyuser-schema" {
  database    = var.database
  role        = "readonlyuser"
  schema      = var.schema
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyuser-tables" {
  database    = var.database
  role        = "readonlyuser"
  schema      = var.schema
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_default_privileges" "readonlyuser-default-tables" {
  database = var.database
  role     = "readonlyuser"
  schema   = var.schema

  owner       = "m_${var.schema}"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyuser-sequence" {
  database    = var.database
  role        = "readonlyuser"
  schema      = var.schema
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}

