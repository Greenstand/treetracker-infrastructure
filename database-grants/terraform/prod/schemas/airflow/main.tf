resource "postgresql_schema" "microservice_schema" {
  name  = "airflow"
  owner = "doadmin"

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_password" "s_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "service_user" {
  name     = "s_airflow"
  login    = true
  password = random_password.s_password.result
  search_path = [ "airflow" ]
}


resource "postgresql_grant" "service-user-usage" {
  database    = "treetracker"
  role        = "s_airflow"
  schema      = "airflow"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "table-service-user" {
  database    = "treetracker"
  role        = "s_airflow"
  schema      = "airflow"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}

resource "postgresql_grant" "sequence-service-user" {
  database    = "treetracker"
  role        = "s_airflow"
  schema      = "airflow"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

}
