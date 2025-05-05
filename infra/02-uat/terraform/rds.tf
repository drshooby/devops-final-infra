module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "uatdb"

  engine            = "postgres"
  engine_version    = "17.1"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name  = "uatdb"
  username = "dbmaster"
  password = var.db_password
  port     = "5432"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [
    module.vpc.default_security_group_id,
    aws_security_group.rds_ingress_from_my_ip.id
  ]

  availability_zone = var.db_az

  tags = var.tags

  # DB subnet group
  create_db_subnet_group = true
  # THIS IS FOR DEV DO NOT PUT THE DB IN A PUBLIC SUBNET!!!
  subnet_ids             = module.vpc.public_subnets

  # DB parameter group
  family = "postgres17"

  # DB option group
  major_engine_version = "17.1"

  # Database Deletion Protection
  deletion_protection = false
}