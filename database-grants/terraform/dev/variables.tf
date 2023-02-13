variable "host" {
  type  = string
  value = "db-postgresql-sfo2-nextgen-do-user-1067699-0.db.ondigitalocean.com"
}

variable "port" {
  type  = number
  value = 25060
}

variable "password" {
  type      = string
  sensitive = true
}
