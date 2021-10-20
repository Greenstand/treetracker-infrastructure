module "airflow_schema" {
  source = "./schemas/airflow"
  providers = {
     postgresql = postgresql.treetracker
  }
}
