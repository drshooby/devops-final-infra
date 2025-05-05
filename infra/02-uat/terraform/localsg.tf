resource "aws_security_group" "rds_ingress_from_my_ip" {
  name        = "rds-from-my-ip"
  description = "Allow Postgres access from my IP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Postgres from my IP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}