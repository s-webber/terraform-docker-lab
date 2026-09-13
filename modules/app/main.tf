terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_network" "frontend_network" {
  name = "terraform-frontend-network"
}

resource "docker_network" "backend_network" {
  name = "terraform-backend-network"
}

resource "docker_volume" "postgres_data" {
  name = "terraform-postgres-data"
}

resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

resource "docker_container" "nginx" {
  name  = "terraform-nginx"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.nginx_port
  }

  networks_advanced {
    name = docker_network.frontend_network.name
  }

  volumes {
    host_path      = abspath("${path.root}/nginx/nginx.conf")
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }

  depends_on = [
    docker_container.app
  ]
}

resource "docker_image" "postgres" {
  name = "postgres:16-alpine"
}

resource "docker_container" "postgres" {
  name  = "terraform-postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
    "POSTGRES_DB=${var.postgres_db}"
  ]

  networks_advanced {
    name = docker_network.backend_network.name
  }

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test = [
      "CMD-SHELL",
      "pg_isready -U ${var.postgres_user} -d ${var.postgres_db}"
    ]

    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }

  wait         = true
  wait_timeout = 60
}

resource "docker_image" "app" {
  name = "terraform-flask-app:latest"

  build {
    context = "${path.root}/app"
  }
}

resource "docker_container" "app" {
  name  = "terraform-flask-app"
  image = docker_image.app.image_id

  env = [
    "DB_HOST=terraform-postgres",
    "DB_PORT=5432",
    "DB_NAME=${var.postgres_db}",
    "DB_USER=${var.postgres_user}",
    "DB_PASSWORD=${var.postgres_password}"
  ]

  networks_advanced {
    name = docker_network.frontend_network.name
  }

  networks_advanced {
    name = docker_network.backend_network.name
  }

  healthcheck {
    test = [
      "CMD-SHELL",
      "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:5000/health')\""
    ]

    interval     = "5s"
    timeout      = "3s"
    retries      = 10
    start_period = "5s"
  }

  wait         = true
  wait_timeout = 60

  depends_on = [
    terraform_data.postgres_init
  ]
}

resource "terraform_data" "postgres_init" {
  triggers_replace = [
    docker_container.postgres.id
  ]

  provisioner "local-exec" {
    command = <<-EOT
      docker exec terraform-postgres \
        psql \
        -U "${var.postgres_user}" \
        -d "${var.postgres_db}" \
        -c "CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          name TEXT NOT NULL
        );"

      docker exec terraform-postgres \
        psql \
        -U "${var.postgres_user}" \
        -d "${var.postgres_db}" \
        -c "INSERT INTO users (name)
            SELECT 'Alice'
            WHERE NOT EXISTS (
              SELECT 1 FROM users WHERE name = 'Alice'
            );"

      docker exec terraform-postgres \
        psql \
        -U "${var.postgres_user}" \
        -d "${var.postgres_db}" \
        -c "INSERT INTO users (name)
            SELECT 'Bob'
            WHERE NOT EXISTS (
              SELECT 1 FROM users WHERE name = 'Bob'
            );"
    EOT
  }

  depends_on = [
    docker_container.postgres
  ]
}
