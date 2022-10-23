
module "microservice_schema" {
  source                    = "./../../modules/microservice_schema"
  schema                    = "reporting"
  service_user_table_grants = ["SELECT", "INSERT", "UPDATE", "DELETE"] # allow delete from this schema
}

resource "postgresql_grant" "stakeholder_schema" {
  database    = "treetracker"
  role        = "s_reporting"
  schema      = "stakeholder"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "stakeholder_children_function" {
  database    = "treetracker"
  role        = "s_reporting"
  schema      = "stakeholder"
  object_type = "function"
  privileges  = ["EXECUTE"]
}

resource "postgresql_grant" "stakeholder_table" {
  database    = "treetracker"
  role        = "s_reporting"
  schema      = "stakeholder"
  object_type = "table"
  privileges  = ["SELECT"]
}





