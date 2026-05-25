module "eks_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.23.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # 1. AWS LOAD BALANCER CONTROLLER
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    values = [yamlencode({
      tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
      nodeSelector = { role = "system" }
      webhook = {
        tolerations  = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
        nodeSelector = { role = "system" }
      }
    })]
  }

  # 2. NGINX INGRESS
  enable_ingress_nginx = true
  ingress_nginx = {
    values = [yamlencode({
      controller = {
        replicaCount = 2
        tolerations  = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
        nodeSelector = { role = "system" }
        config = {
          "force-ssl-redirect" = "false"
          "ssl-redirect"       = "false"
        }
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

 enable_argocd = true
  argocd = {
    values = [yamlencode({
      # ArgoCD Server configuration
      server = {
        service = { type = "ClusterIP" }
        tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
        nodeSelector = { role = "system" }
      }
      # ArgoCD Image Updater
      image-updater = {
        enabled = true
        tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
        nodeSelector = { role = "system" }
      }

      # Argo Rollouts
      controller = {
        # This belongs to the Rollouts chart
      }
      
      # Argo Notifications
      notifications = {
        enabled = true
        tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }]
        nodeSelector = { role = "system" }
      }
    })]
  }

  # 4. KUBE PROMETHEUS STACK
  enable_kube_prometheus_stack = true
  kube_prometheus_stack = {
    values = [yamlencode({
      prometheus = {
        prometheusSpec = { retention = "5d" }
      }
      grafana = {
        adminPassword = "admin"
        service = { type = "ClusterIP" }
      }
    })]
  }

  # 5. CORE ADDONS
  enable_metrics_server   = true
  enable_external_secrets = true

  depends_on = [module.eks]
  tags       = local.common_tags
}
