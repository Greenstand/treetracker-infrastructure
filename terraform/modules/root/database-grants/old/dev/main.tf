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

