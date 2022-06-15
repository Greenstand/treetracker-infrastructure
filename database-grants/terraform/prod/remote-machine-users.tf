resource "random_password" "cvat_annotator_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "postgresql_role" "cvat_annotator" {
  provider = "postgresql.treetracker"
  name     = "cvat_annotator"
  login    = true
  password = random_password.cvat_annotator_password.result
}
