terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

module "app" {
  source = "./modules/app"

  nginx_port        = var.nginx_port
  postgres_user     = var.postgres_user
  postgres_password = var.postgres_password
  postgres_db       = var.postgres_db
}
