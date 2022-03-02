
module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "field_data"
}

resource "postgresql_grant" "legacy_field_data_access" {
  database    = "treetracker"
  role        = "s_field_data"
  schema      = "public"
  object_type = "table"
#  objects     = ["trees", "planter_registrations", "planter"]
  privileges  = ["SELECT", "INSERT"]
}

resource "postgresql_grant" "legacy_field_data_access_sequence" {
  database    = "treetracker"
  role        = "s_field_data"
  schema      = "public"
  object_type = "sequence"
  privileges  = ["SELECT", "USAGE"]
}
