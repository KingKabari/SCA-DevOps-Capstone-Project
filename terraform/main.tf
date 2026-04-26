resource "docker_network" "app_network" {
  name     = var.network_name
  driver   = var.network_driver
  internal = var.network_internal
}

locals {
  image_web = length(trimspace(var.image_web)) > 0 ? var.image_web : var.image
  image_app = length(trimspace(var.image_app)) > 0 ? var.image_app : var.image
  image_db  = length(trimspace(var.image_db)) > 0 ? var.image_db : var.image
}

resource "docker_container" "web" {
  name    = "web_node"
  image   = local.image_web
  command = ["sleep", "infinity"]
  restart = var.restart_policy

  ports {
    internal = var.web_container_port
    external = var.web_host_port
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  healthcheck {
    test         = ["CMD-SHELL", "curl -f http://localhost:${var.web_container_port}/health || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = var.healthcheck_start_period
  }
}

resource "docker_container" "app" {
  name    = "app_node"
  image   = local.image_app
  command = ["sleep", "infinity"]
  restart = var.restart_policy

  networks_advanced {
    name = docker_network.app_network.name
  }

  healthcheck {
    test         = ["CMD-SHELL", "curl -f http://localhost:${var.app_container_port}/health || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = var.healthcheck_start_period
  }
}

resource "docker_container" "db" {
  name    = "db_node"
  image   = local.image_db
  command = ["sleep", "infinity"]
  restart = var.restart_policy

  networks_advanced {
    name = docker_network.app_network.name
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U postgres || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = var.healthcheck_start_period
  }
}