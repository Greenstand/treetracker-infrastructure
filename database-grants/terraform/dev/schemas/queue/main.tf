module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "queue"
  service_user_table_grants = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "random_password" "s_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "service_user" {
  name        = "s_queue"
  login       = true
  password    = random_password.s_password.result
  search_path = ["queue"]
}


resource "postgresql_grant" "service-user-usage" {
  database    = "treetracker"
  role        = "s_queue"
  schema      = "queue"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "table-service-user" {
  database    = "treetracker"
  role        = "s_queue"
  schema      = "queue"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant" "sequence-service-user" {
  database    = "treetracker"
  role        = "s_queue"
  schema      = "queue"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

}