
module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "treetracker"
}
resource "postgresql_grant" "legacy_field_data_access" {
  database    = "treetracker"
  role        = "s_treetracker"
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT", "INSERT"]
}

resource "postgresql_grant" "legacy_field_data_access_sequence" {
  database    = "treetracker"
  role        = "s_treetracker"
  schema      = "public"
  object_type = "sequence"
  privileges  = ["SELECT", "USAGE"]
}

