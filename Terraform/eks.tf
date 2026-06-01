module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  authentication_mode         = "API"
  create_cloudwatch_log_group = false

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {

    # ─────────────────────────────────────────────
    # SYSTEM — sirf AWS core components
    # coredns, kube-proxy, vpc-cni, ebs-csi
    # ─────────────────────────────────────────────
    system = {
      node_group_name = "${var.cluster_name}-system"
      instance_types  = ["t3.micro"]
      capacity_type   = "ON_DEMAND"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      additional_security_group_ids = [aws_security_group.additional_node_sg.id]

      labels = { role = "system" }

      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }

    # ─────────────────────────────────────────────
    # INFRA — Karpenter, ArgoCD, Prometheus,
    #         cert-manager, external-secrets
    # ─────────────────────────────────────────────
    infra = {
      node_group_name = "${var.cluster_name}-infra"
      instance_types  = ["t3.micro"]
      capacity_type   = "ON_DEMAND"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      additional_security_group_ids = [aws_security_group.additional_node_sg.id]

      labels = { role = "infra" }

      taints = [{
        key    = "InfraOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }

  }

  tags = {
    Environment              = var.environment
    ManagedBy                = "Terraform"
    "karpenter.sh/discovery" = var.cluster_name
  }
}
# ─────────────────────────────────────────────
# Karpenter IAM — Pod Identity
# ─────────────────────────────────────────────
module "karpenter_iam" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = module.eks.cluster_name

  enable_pod_identity             = true
  create_pod_identity_association = true
  namespace                       = "karpenter"
  service_account                 = "karpenter"

  create_node_iam_role    = true
  create_access_entry     = true
  create_instance_profile = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  depends_on = [module.eks]
}
