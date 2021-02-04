resource "random_password" "treetracker_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "treetracker" {
  provider = "postgresql.treetracker"
  name     = "treetracker"
  login    = true
  password = random_password.treetracker_password.result
}

resource "random_password" "data_pipeline_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "data_pipeline" {
  provider = "postgresql.data_pipeline"
  name     = "data_pipeline"
  login    = true
  password = random_password.data_pipeline_password.result
}

resource "postgresql_grant" "data-pipeline-public-table" {
  provider = "postgresql.data_pipeline"
  database    = "treetracker"
  role        = "data_pipeline"
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}

resource "postgresql_grant" "data-pipeline-public-sequence" {
  provider = "postgresql.data_pipeline"
  database    = "treetracker"
  role        = "data_pipeline"
  schema      = "public"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}
