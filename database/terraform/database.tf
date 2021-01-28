
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
}



resource "digitalocean_database_replica" "treetracker-postgres-read-replica" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "read-replica"
  size       = "db-s-1vcpu-1gb"
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



resource "digitalocean_database_user" "admin-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "u_admin"
}

resource "digitalocean_database_user" "manager-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "u_manager"
}

resource "digitalocean_database_user" "analyst-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "u_analyst"
}

resource "digitalocean_database_user" "token-issuer-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "u_token_issuer"
}

resource "digitalocean_database_user" "read-only-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "u_read_only"
}


resource "digitalocean_database_user" "map-service-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "s_map"
}

resource "digitalocean_database_user" "admin-panel-service-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "s_admin_panel"
}

resource "digitalocean_database_user" "data-pipeline-service-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "s_data_pipeline"
}

resource "digitalocean_database_user" "wallet-service-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "s_wallet"
}

resource "digitalocean_database_user" "field-service-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "s_field"
}

resource "digitalocean_database_user" "treetracker-service-user" {
  cluster_id = digitalocean_database_cluster.treetracker-postgres-cluster.id
  name       = "s_treetracker"
}

