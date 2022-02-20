module "airflow_schema" {
  source = "./schemas/airflow"
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

module "webmap_schema" {
  source = "./schemas/webmap"
  providers = {
     postgresql = postgresql.treetracker
  }
}

module "stakeholder_schema" {
  source = "./schemas/stakeholder"
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

module "regions_schema" {
  source = "./schemas/regions"
  providers = {
     postgresql = postgresql.treetracker
  }
}

module "messaging_schema" {
  source = "./schemas/messaging"
  providers = {
     postgresql = postgresql.treetracker
  }
}
