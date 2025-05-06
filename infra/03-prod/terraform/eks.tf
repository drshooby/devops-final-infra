module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "prod-cluster"
  cluster_version = "1.31"

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true
  # cluster_endpoint_public_access_cidrs = [ "${var.my_ip}/32" ]

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    group_1 = {
      instance_types = ["t2.medium"]
      min_size     = 2
      max_size     = 2
      desired_size = 2

      additional_security_group_rules = {
        allow_all_node_to_node = {
          description              = "Allow all traffic between nodes in the same SG"
          protocol                 = "-1"
          from_port                = 0
          to_port                  = 0
          type                     = "ingress"
          source_security_group_id = "self"
        }
      }
    }
  }

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}