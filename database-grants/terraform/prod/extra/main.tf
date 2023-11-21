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

resource "postgresql_grant" "wallet-operator-schema-public" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "public"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "wallet-operator-table-public" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}


resource "postgresql_grant" "wallet-operator-seq-public" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "public"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]

}


resource "postgresql_grant" "wallet-operator-schema-herbarium" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "herbarium"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "wallet-operator-table-herbarium" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "herbarium"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}


resource "postgresql_grant" "wallet-operator-seq-herbarium" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "herbarium"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}


resource "postgresql_grant" "wallet-operator-schema-stakeholder" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "stakeholder"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "wallet-operator-table-stakeholder" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "stakeholder"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}


resource "postgresql_grant" "wallet-operator-seq-stakeholder" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "stakeholder"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}


resource "postgresql_grant" "wallet-operator-schema-treetracker" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "treetracker"
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "wallet-operator-table-treetracker" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "treetracker"
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}


resource "postgresql_grant" "wallet-operator-seq-treetracker" {
  database    = "treetracker"
  role        = "wallet_operator"
  schema      = "treetracker"
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT"]
}
