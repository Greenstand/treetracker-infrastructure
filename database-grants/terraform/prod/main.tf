
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

module "earnings_schema" {
  source = "./schemas/earnings"
  providers = {
     postgresql = postgresql.treetracker
  }
}

module "webmap_schema" {
  source = "./schemas/webmap"
  providers = {
     postgresql = postgresql.treetracker
  }
}

module "airflow_schema" {
  source = "./schemas/airflow"
  providers = {
     postgresql = postgresql.treetracker
  }
}

