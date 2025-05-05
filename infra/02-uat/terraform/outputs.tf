output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}