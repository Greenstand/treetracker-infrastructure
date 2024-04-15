module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "queue"
  service_user_table_grants = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}
