# ─────────────────────────────────────────────
# EKS Cluster + Node Groups + Addons
# ─────────────────────────────────────────────

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
      configuration_values = jsonencode({
        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }
        ]
      })
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
      service_account_role_arn    = aws_iam_role.addon_roles["ebs-csi"].arn
      configuration_values = jsonencode({
        controller = {
          tolerations = [
            {
              key      = "CriticalAddonsOnly"
              operator = "Equal"
              value    = "true"
              effect   = "NoSchedule"
            }
          ]
        }
      })
    }

    eks-pod-identity-agent = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {

    # ── System Node Group ──────────────────────
    system = {
      node_group_name = "${var.cluster_name}-system"
      instance_types  = ["c7i-flex.large"]
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

    # ── Infra Node Group ───────────────────────
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

# EBS CSI Driver IAM — Pod Identity
# ─────────────────────────────────────────────

# 1. Trust Policy jo Pod Identity Agent ko allow karti hai
data "aws_iam_policy_document" "ebs_csi_pod_identity_assume" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# 2. IAM Role banana
resource "aws_iam_role" "ebs_csi_pod_identity" {
  name               = "${var.cluster_name}-ebs-csi-pod-identity-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_pod_identity_assume.json

  tags = {
    Environment = var.environment
  }
}

# 3. AWS ki AWS-managed EBS Policy attach karna
resource "aws_iam_role_policy_attachment" "ebs_csi_pod_identity" {
  role       = aws_iam_role.ebs_csi_pod_identity.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# 4. Role ko EBS CSI ke Service Account ke sath map karna
resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_pod_identity.arn
}


# ─────────────────────────────────────────────
# Karpenter IAM + Pod Identity
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
