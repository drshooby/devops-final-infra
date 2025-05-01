resource "aws_security_group" "private_instances" {
  name        = "qa-instances-sg"
  description = "Security group for QA instances"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "machines" {
  ami                    = "ami-03e4e59b20d79eeab"
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.private_instances.id]
  iam_instance_profile    = "EC2_SSM"
  tags = {
    Name = "QA"
  }
}