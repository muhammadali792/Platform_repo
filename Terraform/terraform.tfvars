eks_addons_security_config = {
  /*
  # Pehle se maujood configs...
  aws-load-balancer-controller = {
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
    policy_arn      = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  }

  external-secrets = {
    namespace       = "kube-system"
    service_account = "external-secrets"
    policy_arn      = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  }
  */
  aws-ebs-csi-driver = {
    namespace       = "kube-system"
    service_account = "ebs-csi-controller-sa"
    policy_arn      = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }
  

  argocd-image-updater = {
    namespace       = "argocd"
    service_account = "argocd-image-updater"
    policy_arn      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }
}
