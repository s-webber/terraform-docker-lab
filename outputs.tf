output "nginx_url" {
  value = module.app.nginx_url
}

output "terraform_root" {
  value = path.root
}
