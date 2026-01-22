
resource "digitalocean_database_cluster" "treetracker-postgres-cluster" {
  name       = "treetracker-cluster"
  engine     = "pg"
  version    = "11"
  size       = "db-s-4vcpu-8gb"
  region     = "nyc1"
  node_count = 2
}

# TODO: set up dns to point to this database so it's easier to connect to db
#resource "digitalocean_record" "CNAME-database" {
#  domain = digitalocean_domain.ambassador-host.name
#  type = "CNAME"
#  name = "www"
#  value = "@"
#}

resource "digitalocean_database_firewall" "treetracker-database-fw" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id

  rule {
    type  = "tag"
    value = "treetracker-database-access"
  }

  rule {
    type  = "tag"
    value = "bastion"
  }

  rule {
    type  = "ip_addr"
    value = "157.230.2.227"
  }

  rule {
    type  = "ip_addr"
    value = "157.230.8.187"
  }

  rule {
    type  = "ip_addr"
    value = "69.209.22.114"
  }
}

#resource "digitalocean_database_replica" "treetracker-postgres-read-replica" {
#  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
#  name       = "read-replica"
#  size       = "db-s-4vcpu-8gb"
#  region     = "nyc1"
#  tags       = ["foresmatic"]
#}

#resource "digitalocean_database_replica_firewall" "treetracker-database-replica-fw" {
#  cluster_id = digitalocean_database_replica.treetracker-postgres-read-replica.id
#
#  rule {
#    type  = "tag"
#    value = "treetracker-database-access"
#  }
#}

resource "digitalocean_database_db" "treetracker-database" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "treetracker"
}

resource "digitalocean_database_db" "data-pipeline-database" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "data_pipeline"
}

resource "digitalocean_database_db" "ckan-database" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "ckan"
}

#resource "digitalocean_database_db" "ckan-datastore-database" {
#  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
#  name       = "ckan_datastore"
#}
#
#resource "digitalocean_database_db" "world-bank-backup-database" {
#  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
#  name       = "world_bank_backup"
#}

