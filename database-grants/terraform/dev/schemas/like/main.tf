module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "like"
  service_user_table_grants = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "random_password" "s_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "service_user" {
  name        = "s_like"
  login       = true
  password    = random_password.s_password.result
  search_path = ["like"]
}


resource "postgresql_grant" "service-user-usage" {
  database    = "treetracker"
  role        = "s_like"
  schema      = "like"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "table-service-user" {
  database    = "treetracker"
  role        = "s_like"
  schema      = "like"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant" "sequence-service-user" {
  database    = "treetracker"
  role        = "s_like"
  schema      = "like"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

}