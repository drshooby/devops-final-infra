output "ecr_repository_urls" {
  value = { for k, repo in module.ecr : k => repo.repository_url }
}