
module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "treetracker"
}

resource "postgresql_grant" "legacy_stakeholder_access" {
  database    = "treetracker"
  role        = "s_treetracker"
  schema      = "stakeholder"
  object_type = "table"
  privileges  = ["SELECT"]
}
