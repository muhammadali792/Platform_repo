eks_addons_security_config = {
  "lb-controller" = {
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
    policy_arn      = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
  }
  "external-secrets" = {
    namespace       = "kube-system"
    service_account = "external-secrets"
    policy_arn      = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  }
}
