resource "postgresql_schema" "keycloak_schema" {
  name  = "keycloak"
  owner = "doadmin"
}

resource "random_password" "s_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "service_user" {
  name        = "s_keycloak"
  login       = true
  password    = random_password.s_password.result
  search_path = ["keycloak", "public"]
}

resource "postgresql_grant" "service-user-usage" {
  database    = "treetracker"
  role        = postgresql_role.service_user.name
  schema      = postgresql_schema.keycloak_schema.name
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "table-service-user" {
  database    = "treetracker"
  role        = postgresql_role.service_user.name
  schema      = postgresql_schema.keycloak_schema.name
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant" "sequence-service-user" {
  database    = "treetracker"
  role        = postgresql_role.service_user.name
  schema      = postgresql_schema.keycloak_schema.name
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}
