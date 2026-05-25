module "eks_addons" {
  # Version 2.x update kiya gaya hai
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 2.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # AWS LOAD BALANCER CONTROLLER
  enable_aws_load_balancer_controller = true

  # NGINX INGRESS
  enable_ingress_nginx = true
  ingress_nginx = {
    values = [yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"                    = "external"
            "service.beta.kubernetes.io/aws-load-balancer-target-group-attributes" = "deregistration_delay.timeout_seconds=30"
            "service.beta.kubernetes.io/aws-load-balancer-scheme"                  = "internet-facing"
            "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol"    = "HTTP"
            "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"        = "80"
            "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path"        = "/healthz"
            "service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval"    = "10"
          }
        }
      }
    })]
  }

  # ARGO CD
  enable_argocd = true

  # KUBE PROMETHEUS STACK
  enable_kube_prometheus_stack = true

  # CORE ADDONS
  enable_metrics_server   = true
  enable_external_secrets = true

  depends_on = [module.eks]
  tags       = local.common_tags
}
