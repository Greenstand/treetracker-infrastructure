

resource "postgresql_schema" "wallet_schema" {
  provider = "postgresql.treetracker"
  name  = "wallet"
  owner = "doadmin"
}

resource "postgresql_grant" "wallet-microservice-user-usage" {
  database    = "treetracker"
  role        = "s_wallet"
  schema      = "wallet"
  object_type = "schema"
  privileges  = ["LOGIN", "USAGE"]
}

resource "postgresql_grant" "wallet-microservice-user" {
  database    = "treetracker"
  role        = "s_wallet"
  schema      = "wallet"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE"]
}


#resource "postgresql_grant" "wallet-microservice-migration-executer" {
#  database    = "treetracker"
#  role        = "m_wallet"
#  schema      = "wallet"
#  object_type = "schema"
#  privileges  = ["LOGIN", "USAGE", "CREATE"]
#}

