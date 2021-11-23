resource "random_password" "readonlyuser_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "readonlyuser_human" {
  provider = "postgresql.treetracker"
  name     = "readonlyuser"
  login    = true
  password = random_password.readonlyuser_password.result
}

resource "postgresql_grant" "readonlyyuser_select_field" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "field"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_field" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "field"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_sequence_field" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "field"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_select_public" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_sequence_public" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "public"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_import" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "import"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_select_import" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "import"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_sequence_import" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "import"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_operations" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "operations"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_select_operations" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "operations"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_sequence_operations" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "operations"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_token_management" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "token_management"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_select_token_management" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "token_management"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_select_sequence_management" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "token_management"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_treetracker" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "treetracker"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_select_treetracker" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "treetracker"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_sequence_treetracker" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "treetracker"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_wallet" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "wallet"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_select_wallet" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "wallet"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_sequence_wallet" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "wallet"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_webmap" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "webmap"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_sequence_webmap" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "webmap"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_airflow" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "airflow"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_select_airflow" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "airflow"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_sequence_airflow" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "airflow"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_usage_reporting" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "reporting"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_select_reporting" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "reporting"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_sequence_reporting" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "reporting"
  object_type = "sequence"
  privileges  = ["SELECT"]
}


resource "postgresql_grant" "readonlyyuser_usage_earnings" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "earnings"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "readonlyyuser_select_earnings" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "earnings"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "readonlyyuser_sequence_earnings" {
  provider = "postgresql.treetracker"
  database    = "treetracker"
  role        = "readonlyuser"
  schema      = "earnings"
  object_type = "sequence"
  privileges  = ["SELECT"]
}

