
module "field_schema" {
  source = "./schemas/field"
  providers = {
     postgresql = postgresql.treetracker
  }
}


