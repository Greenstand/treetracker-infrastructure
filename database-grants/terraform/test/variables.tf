variable "host" {
  type    = string
  default = "db-postgresql-sfo2-40397-do-user-1067699-0.db.ondigitalocean.com"
}

variable "port" {
  type    = number
  default = 25060
}

variable "password" {
  type      = string
  sensitive = true
}
