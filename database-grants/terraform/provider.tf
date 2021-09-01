variable "host" {
  type = string
}

variable "port" {
  type = number
}

variable "password" {
  type = string
}

terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.11.0"
    }
  }
}

provider "postgresql" {
  alias    = "treetracker"
  database        = "treetracker"

  host            = var.host
  port            = var.port
  username        = "doadmin"
  password        = var.password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

provider "postgresql" {
  alias    = "data_pipeline"
  database        = "data_pipeline"

  host            = var.host
  port            = var.port
  username        = "doadmin"
  password        = var.password 
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

