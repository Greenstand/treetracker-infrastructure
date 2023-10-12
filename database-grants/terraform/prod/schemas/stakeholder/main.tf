
module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "stakeholder"
}

resource "postgresql_grant" "readonly_entity" {
  database    = "treetracker"
  role        = "s_stakeholder"
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]
}


