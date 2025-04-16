output "db_instance_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_password" {
  value     = random_password.password.result
  sensitive = true
}

output "db_username" {
  value = module.rds.db_instance_username
}
