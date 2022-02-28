
module "microservice_schema" {
  source = "./../../modules/microservice_schema"
  schema = "messaging"
  service_user_table_grants = ['SELECT', 'INSERT', 'UPDATE', 'DELETE']
}


