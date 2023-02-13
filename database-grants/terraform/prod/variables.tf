variable "host" {
  type = string
}

variable "port" {
  type  = number
  value = 25060
}

variable "password" {
  type      = string
  sensitive = true
}
