# 1. Yeh block variables par loop chala kar har addon ke liye alag se IAM Role banata hai aur naye module ki wajah se automatically un par EKS Pod Identity ki safe trust policy lagata hai.
module "eks_pod_identity_roles" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-eks-role"
  version  = "~> 5.0"
  for_each = var.eks_addons_security_config

  role_name = "${module.eks.cluster_name}-${each.key}-pod-identity"

  role_policy_arns = {
    addon_policy = each.value.policy_arn
  }

  tags = local.common_tags
}

# 2. Yeh block unhi bane huay AWS IAM Roles ko aapke Kubernetes cluster ke Service Accounts ke sath aapas mein jod (bind) deta hai taake pods ko permissions mil sakein.
resource "aws_eks_pod_identity_association" "addon_associations" {
  for_each = var.eks_addons_security_config

  cluster_name    = module.eks.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = module.eks_pod_identity_roles[each.key].iam_role_arn
}

# 3. Yeh variables ki declaration hai jo batati hai ke input data ka structure kaisa hoga.
variable "eks_addons_security_config" {
  description = "Map of EKS addons configuration for dynamic Pod Identity IAM roles execution"
  type = map(object({
    namespace       = string
    service_account = string
    policy_arn      = string
  }))
}
