


module "microservice_schema" {
  source = "./modules/microservice_schema"

  for_each = toset([
	      "field",
              "wallet", 
              "treetracker"
	     ])
  schema = each.key
  providers = {
     postgresql = postgresql.treetracker
  }
}


