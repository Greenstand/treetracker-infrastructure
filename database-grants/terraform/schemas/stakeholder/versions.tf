terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.11.0"
    }
  }

  required_version = "0.14.0"
}
