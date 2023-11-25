
module "microservice_schema" {
  source                    = "./../../modules/microservice_schema"
  schema                    = "denormalized"
  service_user_table_grants = ["SELECT", "INSERT", "UPDATE", "DELETE"] # allow delete from this schema
}


