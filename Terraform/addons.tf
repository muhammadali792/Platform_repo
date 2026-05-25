module "eks_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # AWS LOAD BALANCER CONTROLLER
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    values = [yamlencode({
      tolerations = [{
        key      = "CriticalAddonsOnly"
        operator = "Equal"
        value    = "true"
        effect   = "NoSchedule"
      }]
      nodeSelector = {
        role = "system"
      }
    })]
  }

  # NGINX INGRESS
  enable_ingress_nginx = true
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  ingress_nginx = {
    values = [yamlencode({
      controller = {
        replicaCount = 2
        tolerations = [{
          key      = "CriticalAddonsOnly"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]
        nodeSelector = { role = "system" }
        config = {
          "force-ssl-redirect" = "false"
          "ssl-redirect"       = "false"
        }
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"                   = "ip"
            "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
            "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
          }
        }
      }
      # Admission Webhooks ke liye teeno jagah toleration add kardi hai
      admissionWebhooks = {
        enabled = true
        patch = {
          tolerations  = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
          nodeSelector = { role = "system" }
        }
        createSecretJob = {
          tolerations  = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
          nodeSelector = { role = "system" }
        }
        patchWebhookJob = {
          tolerations  = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
          nodeSelector = { role = "system" }
        }
      }
    })]
  }
  /*
  # ARGOCD
  enable_argocd = true
  argocd = {
    namespace = "argocd"
    values = [yamlencode({
      server = {
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hosts            = ["argocd.${var.domain_name}"]
        }
      }
    })]
  }
  */
  # CORE ADDONS
  enable_metrics_server   = true
  enable_external_secrets = true

  depends_on = [module.eks]
  tags       = local.common_tags
}
