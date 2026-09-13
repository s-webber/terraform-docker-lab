Simple project to allow me to experiment with Terraform and Docker.
Creates a Nginx server, Python Flask application and Postgres database.
Not intended for use in production, just a learning exercise.

To use the default configuration:
```
cp dev.tfvars.example dev.tfvars
```

To format, validate, plan and apply:
```
terraform fmt -recursive
terraform validate
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

To call Nginx:
```
curl http://localhost:9090
curl http://localhost:9090/users
```

To view outputs:
```
terraform output
terraform output nginx_url
```

To see Terraform's representation of the infrastructure:
```
terraform show
terraform state list
terraform graph
```

To view network details:
```
docker network ls
docker network inspect terraform-app-network
```

To view postgres status:
```
docker inspect terraform-postgres --format '{{json .Config.Healthcheck}}'
docker inspect terraform-postgres --format '{{.State.Health.Status}}'
```

To query the database directly:
```
docker exec terraform-postgres \
  psql -U labuser -d labdb -c "SELECT * FROM users;"
```

To destroy the environment:
```
terraform destroy
terraform state list
docker ps -a
docker network ls
docker volume ls
```
