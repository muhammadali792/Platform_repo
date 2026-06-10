# Local configuration mapping
locals {
  eks_addons_security_config = {
    "ebs-csi" = {
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
      policy_arn      = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    },
    "argocd-image-updater" = {
      namespace       = "argocd"
      service_account = "argocd-image-updater-sa"
      policy_arn      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    }
  }
}

# Dynamic IAM Roles for EKS Addons
resource "aws_iam_role" "addon_roles" {
  for_each = local.eks_addons_security_config

  name = substr("${module.eks.cluster_name}-${each.key}-role", 0, 64)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "addon_roles" {
  for_each   = local.eks_addons_security_config
  role       = aws_iam_role.addon_roles[each.key].name
  policy_arn = each.value.policy_arn
}

resource "aws_eks_pod_identity_association" "addon_associations" {
  for_each        = local.eks_addons_security_config
  cluster_name    = module.eks.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.addon_roles[each.key].arn
  depends_on      = [module.eks]
}
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}
