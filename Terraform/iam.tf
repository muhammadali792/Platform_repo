# =============================================================================
# 1. DYNAMIC IAM ROLES FOR EKS ADDONS (Using Pod Identity)
# =============================================================================
resource "aws_iam_role" "addon_roles" {
  for_each = var.eks_addons_security_config

  # 🟢 FIX: substr use kiya hai taake naam kabhi bhi 64 chars se exceed na ho
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

# =============================================================================
# 2. POLICY ATTACHMENTS FOR ADDON ROLES
# =============================================================================
resource "aws_iam_role_policy_attachment" "addon_roles" {
  for_each   = var.eks_addons_security_config
  role       = aws_iam_role.addon_roles[each.key].name
  policy_arn = each.value.policy_arn
}

# =============================================================================
# 3. EKS POD IDENTITY ASSOCIATIONS
# =============================================================================
resource "aws_eks_pod_identity_association" "addon_associations" {
  for_each        = var.eks_addons_security_config
  cluster_name    = module.eks.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.addon_roles[each.key].arn

  depends_on = [module.eks]
}

# =============================================================================
# 4. AWS SERVICE-LINKED ROLE FOR EC2 SPOT INSTANCES
# =============================================================================
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
  description      = "Service-linked role for EC2 Spot Instances managed by Karpenter"
}
