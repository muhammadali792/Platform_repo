# =============================================================================
# 1. DYNAMIC IAM ROLES FOR EKS ADDONS (Using Pod Identity)
# =============================================================================
resource "aws_iam_role" "addon_roles" {
  for_each = var.eks_addons_security_config

  name = "${module.eks.cluster_name}-${each.key}-pod-identity"

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
# Required globally in the AWS account so Karpenter can provision Spot Instances.
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
  description      = "Service-linked role for EC2 Spot Instances managed by Karpenter"
}

# =============================================================================
# 5. VARIABLES USED IN CONFIGURATION
# =============================================================================
variable "eks_addons_security_config" {
  description = "Map of EKS addons configuration for dynamic Pod Identity IAM roles"
  type = map(object({
    namespace       = string
    service_account = string
    policy_arn      = string
  }))
}
