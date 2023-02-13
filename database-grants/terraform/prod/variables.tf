variable "host" {
  type = string
}

variable "port" {
  type    = number
  default = 25060
}

variable "password" {
  type      = string
  sensitive = true
}
