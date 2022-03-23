locals {
  default_tfsettings = {
    entity_name  = "main"
    project_name = "eks"
    region       = "us-east-1"

    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]

    tags = {
      "Owner" = "yazri"
    }
  }
  tfsettings = local.default_tfsettings
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.8.1"

  cluster_name                    = "${local.tfsettings.entity_name}-eks-${terraform.workspace}"
  cluster_version                 = "1.21"
  vpc_id                          = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids                      = data.terraform_remote_state.network.outputs.private_subnets
  cluster_endpoint_private_access = true

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type               = local.tfsettings.ami_type
    disk_size              = 50
    instance_types         = local.tfsettings.instance_types
    vpc_security_group_ids = ["${data.terraform_remote_state.network.outputs.all-secgrp}"]
  }

  eks_managed_node_groups = {
    on_demand = {
      node_group_name = "${local.tfsettings.entity_name}-ondemand-node-group-${terraform.workspace}"
      min_size        = 1
      max_size        = 5
      desired_size    = 2

      capacity_type = "ON_DEMAND"

      labels = {
        Environment = "${terraform.workspace}"
      }
    }
    spot = {
      node_group_name = "${local.tfsettings.entity_name}-spot-node-group-${terraform.workspace}"
      min_size        = 1
      max_size        = 5
      desired_size    = 2

      capacity_type = "SPOT"

      labels = {
        Environment = "${terraform.workspace}"
      }
    }
  }
}