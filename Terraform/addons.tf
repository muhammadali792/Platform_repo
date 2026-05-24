module "eks_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # =============================================================================
  # AWS LOAD BALANCER CONTROLLER — [ENABLED]
  # =============================================================================
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    role_name = "${var.cluster_name}-aws-lbc"
  }

  # =============================================================================
  # NGINX INGRESS + NLB — [ACTIVE]
  # =============================================================================
  enable_ingress_nginx = true
  ingress_nginx = {
    values = [
      yamlencode({
        controller = {
          replicaCount = 2
          topologySpreadConstraints = [
            {
              maxSkew           = 1
              topologyKey       = "topology.kubernetes.io/zone"
              whenUnsatisfiable = "DoNotSchedule"
              labelSelector = {
                matchLabels = {
                  "app.kubernetes.io/name" = "ingress-nginx"
                }
              }
            }
          ]
          resources = {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "200m", memory = "256Mi" }
          }
          service = {
            type                  = "LoadBalancer"
            externalTrafficPolicy = "Local"
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-type"                                 = "nlb"
              "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
              "service.beta.kubernetes.io/aws-load-balancer-scheme"                                = "internet-facing"
              "service.beta.kubernetes.io/aws-load-balancer-health-check-path"                     = "/healthz"
              "service.beta.kubernetes.io/aws-load-balancer-health-check-port"                     = "10254"
              "service.beta.kubernetes.io/aws-load-balancer-health-check-protocol"                 = "HTTP"
              "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"                       = "ip"
            }
          }
          config = {
            use-forwarded-headers      = "true"
            compute-full-forwarded-for = "true"
          }
        }
      })
    ]
  }

  # =============================================================================
  # ARGOCD — [ACTIVE]
  # =============================================================================
  enable_argocd = true
  argocd = {
    namespace = "argocd"
    values = [
      yamlencode({
        server = {
          ingress = {
            enabled          = true
            ingressClassName = "nginx"
            hosts            = ["argocd.${var.domain_name}"]
            annotations = {
              "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
              "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
              "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
              "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTPS"
            }
            tls = [
              {
                secretName = "argocd-server-tls"
                hosts      = ["argocd.${var.domain_name}"]
              }
            ]
          }
        }
      })
    ]
  }

  # =============================================================================
  # CORE ADDONS
  # =============================================================================
  enable_metrics_server   = true
  enable_external_secrets = true

  depends_on = [module.eks]
  tags       = local.common_tags
}
