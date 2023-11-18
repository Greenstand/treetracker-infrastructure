resource "postgresql_grant" "wallet-operator-schema" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "wallet"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "wallet-operator-table" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "wallet"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant" "wallet-operator-seq" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "wallet"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

}
