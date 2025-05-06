resource "aws_security_group" "rds_access" {
  name        = "rds-access-from-eks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Postgres from EKS"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "proddb"

  engine            = "postgres"
  engine_version    = "17.1"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name  = "proddb"
  username = "dbmaster"
  manage_master_user_password	= false
  password = var.db_password
  port     = "5432"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [
    aws_security_group.rds_access.id
  ]

  availability_zone = var.db_az

  tags = var.tags

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  # DB parameter group
  family = "postgres17"

  # DB option group
  major_engine_version = "17.1"

  # Database Deletion Protection
  deletion_protection = false
}