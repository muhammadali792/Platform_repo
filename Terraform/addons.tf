module "eks_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # =============================================================================
  # AWS LOAD BALANCER CONTROLLER — System Node
  # =============================================================================
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    values = [
      yamlencode({
        tolerations = [
          { key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }
        ]
        nodeSelector = { role = "system" }
      })
    ]
  }

  # =============================================================================
  # NGINX INGRESS + NLB — Karpenter Node
  # =============================================================================
  enable_ingress_nginx = true
  ingress_nginx = {
    values = [
      yamlencode({
        controller = {
          replicaCount = 3

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
              "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
              "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
              "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internet-facing"
              "service.beta.kubernetes.io/aws-load-balancer-health-check-path"                 = "/healthz"
              "service.beta.kubernetes.io/aws-load-balancer-health-check-port"                 = "10254"
              "service.beta.kubernetes.io/aws-load-balancer-health-check-protocol"             = "HTTP"
              "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"                   = "ip"
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
  # ARGOCD — Secure Architecture (No Insecure Flags + SSL Redirect)
  # =============================================================================
  enable_argocd = true
  argocd = {
    namespace = "argocd"
    values = [
      yamlencode({
        server = {
          # 🟢 `--insecure` hata diya hai taake internal TLS active ho jaye
          extraArgs = []
          ingress = {
            enabled          = true
            ingressClassName = "nginx"
            hosts            = ["argocd.${var.domain_name}"]
            annotations = {
              # 🟢 SSL Redirection aur Cert-Manager integration annotations
              "cert-manager.io/cluster-issuer"              = "letsencrypt-duckdns"
              "nginx.ingress.kubernetes.io/ssl-redirect"    = "true"
              "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
              # ArgoCD internal TLS use kar raha hai, isliye backend protocol HTTPS hona chahiye
              "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
            }
            tls = [
              {
                secretName = "argocd-server-tls"
                hosts      = ["argocd.${var.domain_name}"]
              }
            ]
          }
          metrics = {
            enabled        = true
            serviceMonitor = { enabled = true, namespace = "monitoring" }
          }
        }
        controller = {
          metrics = {
            enabled        = true
            serviceMonitor = { enabled = true, namespace = "monitoring" }
          }
        }
        repoServer = {
          metrics = {
            enabled        = true
            serviceMonitor = { enabled = true, namespace = "monitoring" }
          }
        }
      })
    ]
  }

  # =============================================================================
  # METRICS SERVER — System Node
  # =============================================================================
  enable_metrics_server = true
  metrics_server = {
    values = [
      yamlencode({
        tolerations = [
          { key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }
        ]
        nodeSelector = { role = "system" }
      })
    ]
  }

  # =============================================================================
  # EXTERNAL SECRETS — Karpenter Node
  # =============================================================================
  enable_external_secrets = true

  # =============================================================================
  # PROMETHEUS + GRAFANA — Secure Ingress Setup
  # =============================================================================
  enable_kube_prometheus_stack = true
  kube_prometheus_stack = {
    values = [
      yamlencode({
        grafana = {
          ingress = {
            enabled          = true
            ingressClassName = "nginx"
            hosts            = ["grafana.${var.domain_name}"]
            annotations = {
              # 🟢 Automatic HTTP to HTTPS redirect & SSL cert matching
              "cert-manager.io/cluster-issuer"              = "letsencrypt-duckdns"
              "nginx.ingress.kubernetes.io/ssl-redirect"    = "true"
              "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
            }
            tls = [
              {
                secretName = "grafana-tls-cert"
                hosts      = ["grafana.${var.domain_name}"]
              }
            ]
          }
        }
        prometheus = {
          ingress = {
            enabled          = true
            ingressClassName = "nginx"
            hosts            = ["prometheus.${var.domain_name}"]
            annotations = {
              # 🟢 Prometheus Dashboard protection & SSL redirection
              "cert-manager.io/cluster-issuer"              = "letsencrypt-duckdns"
              "nginx.ingress.kubernetes.io/ssl-redirect"    = "true"
              "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
            }
            tls = [
              {
                secretName = "prometheus-tls-cert"
                hosts      = ["prometheus.${var.domain_name}"]
              }
            ]
          }
        }
      })
    ]
  }

  # =============================================================================
  # EFS CSI DRIVER — System Node
  # =============================================================================
  enable_aws_efs_csi_driver = true
  aws_efs_csi_driver = {
    values = [
      yamlencode({
        controller = {
          tolerations = [
            { key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }
          ]
          nodeSelector = { role = "system" }
        }
      })
    ]
  }

  # =============================================================================
  # SECRETS STORE CSI DRIVER — System Node
  # =============================================================================
  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true
  secrets_store_csi_driver = {
    values = [
      yamlencode({
        tolerations = [
          { key = "CriticalAddonsOnly", operator = "Exists", effect = "NoSchedule" }
        ]
        nodeSelector = { role = "system" }
      })
    ]
    set = [
      { name = "syncSecret.enabled",   value = "true" },
      { name = "enableSecretRotation", value = "true" }
    ]
  }

  depends_on = [module.eks]
  tags       = local.common_tags
}
