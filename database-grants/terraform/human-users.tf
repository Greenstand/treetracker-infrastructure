
resource "random_password" "accountant_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "accountant_human" {
  provider = "postgresql.treetracker"
  name     = "accountant"
  login    = true
  password = random_password.accountant_password.result
}

resource "random_password" "readonlyuser_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "readonlyuser_human" {
  provider = "postgresql.treetracker"
  name     = "readonlyuser"
  login    = true
  password = random_password.readonlyuser_password.result
}

resource "random_password" "token_issuer_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "token_issuer_human" {
  provider = "postgresql.treetracker"
  name     = "token_issuer"
  login    = true
  password = random_password.token_issuer_password.result
}



resource "random_password" "treetracker_admin_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "treetracker_admin" {
  provider = "postgresql.treetracker"
  name     = "treetracker_admin"
  login    = true
  password = random_password.treetracker_admin_password.result
}

resource "random_password" "treetracker_analyst_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "treetracker_analyst" {
  provider = "postgresql.treetracker"
  name     = "treetracker_analyst"
  login    = true
  password = random_password.treetracker_analyst_password.result
}

resource "random_password" "treetracker_manager_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "treetracker_manager" {
  provider = "postgresql.treetracker"
  name     = "treetracker_manager"
  login    = true
  password = random_password.treetracker_manager_password.result
}
