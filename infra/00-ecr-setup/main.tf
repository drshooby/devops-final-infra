variable "services" {
  type = list(string)
  default = ["frontend", "email-service", "list-service", "metric-service"]
}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"
  version = "~> 1.0"

  for_each = toset(var.services)

  repository_name = each.value

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}