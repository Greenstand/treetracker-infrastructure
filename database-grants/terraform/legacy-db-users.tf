resource "random_password" "treetracker_password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "postgresql_role" "treetracker" {
  provider = "postgresql.treetracker"
  name     = "treetracker"
  login    = true
  password = random_password.treetracker_password.result
}
