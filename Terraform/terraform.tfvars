eks_addons_security_config = {
  "external-secrets" = {
    namespace       = "kube-system"
    service_account = "external-secrets"
    policy_arn      = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  }
}
