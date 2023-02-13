variable "host" {
  type    = string
  default = "db-postgresql-sfo2-nextgen-do-user-1067699-0.db.ondigitalocean.com"
}

variable "port" {
  type    = number
  default = 25060
}

variable "password" {
  type      = string
  sensitive = true
}
