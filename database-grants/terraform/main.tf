
module "field_schema" {
  source = "./schemas/field"
  providers = {
     postgresql = postgresql.treetracker
  }
}


module "wallet_schema" {
  source = "./schemas/wallet"
  providers = {
     postgresql = postgresql.treetracker
  }
}

module "treetracker_schema" {
  source = "./schemas/treetracker"
  providers = {
     postgresql = postgresql.treetracker
  }
}

module "pipeline_schema" {
  source = "./schemas/pipeline"
  providers = {
     postgresql = postgresql.data_pipeline
  }
}

module "webmap_schema" {
  source = "./schemas/webmap"
  providers = {
     postgresql = postgresql.treetracker
  }
}

