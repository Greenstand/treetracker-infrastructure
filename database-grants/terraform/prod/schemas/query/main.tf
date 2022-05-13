
module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "query"
}

resource "postgresql_grant" "query_messaging_schema" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "messaging"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "query_messaging_tables" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "messaging"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "query_treetracker_schema" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "treetracker"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "query_treetracker_tables" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "treetracker"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "query_stakeholder_schema" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "stakeholder"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "query_stakeholder_tables" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "stakeholder"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "query_regions_schema" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "regions"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "query_regions_tables" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "regions"
  object_type = "table"
  privileges  = ["SELECT"]
}

resource "postgresql_grant" "query_public_schema" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE"]
}

resource "postgresql_grant" "query_public_function" {
  database    = "treetracker"
  role        = "s_query"
  schema      = "public"
  object_type = "function"
  privileges  = ["EXECUTE"]
}



