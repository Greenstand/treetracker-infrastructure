resource "random_password" "readonlyuser_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "readonlyuser_human" {
  provider = "postgresql.treetracker"
  name     = "readonlyuser"
  login    = true
  password = random_password.readonlyuser_password.result
}

