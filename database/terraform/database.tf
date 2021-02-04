
resource "digitalocean_database_cluster" "treetracker-postgres-cluster" {
  name       = "treetracker-cluster"
  engine     = "pg"
  version    = "11"
  size       = "db-s-2vcpu-4gb"
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
    type  = "droplet"
    value = "prod-core-services-20200703-01-1612148248329-s-4vcpu-8gb-nyc1-01"
  }

  rule {
    type  = "droplet"
    value = "prod-legacy-core-services-1612148271925-s-2vcpu-4gb-nyc1-01"
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



resource "digitalocean_database_replica" "treetracker-postgres-read-replica" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "read-replica"
  size       = "db-s-2vcpu-4gb"
  region     = "nyc1"
}

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



