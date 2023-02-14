variable "schema" {}

variable "service_user_table_grants" {
  type    = list(string)
  default = ["SELECT", "INSERT", "UPDATE"]
}

variable "database" {
  type    = string
  default = "treetracker"
}
