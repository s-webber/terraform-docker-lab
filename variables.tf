variable "nginx_port" {
  type    = number
  default = 8080
}

variable "postgres_user" {
  type      = string
  sensitive = true
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "postgres_db" {
  type    = string
  default = "labdb"
}
