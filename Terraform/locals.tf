locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  system_scheduling = {
    nodeSelector = { role = "system" }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }]
  }

  infra_scheduling = {
    nodeSelector = { role = "infra" }
    tolerations = [{
      key      = "InfraOnly"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }]
  }

  app_values = {
    argocd = {
      global = {
        nodeSelector = { role = "infra" }
        tolerations = [{
          key      = "InfraOnly"
          operator = "Equal"
          value    = "true"
          effect   = "NoSchedule"
        }]
      }
      server = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
        metrics = {
          enabled = true
        }
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hostname         = "argocd.cloudaura.online"
          tls              = true
          annotations = {
            "cert-manager.io/cluster-issuer"               = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
            "nginx.ingress.kubernetes.io/ssl-redirect"     = "true"
          }
        }
      }
      controller = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
        metrics = {
          enabled = true
        }
      }
      repoServer = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
        metrics = {
          enabled = true
        }
      }
      applicationSet = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
      }
      hooks = {
        enabled      = true
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
      }
      redis = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
      }
    }

    argo_rollouts = {
      controller = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
        metrics = {
          enabled      = true
          nodeSelector = local.infra_scheduling.nodeSelector
          tolerations  = local.infra_scheduling.tolerations
        }
      }
      dashboard = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
      }
    }

    prometheus = {
      prometheus = {
        prometheusSpec = {
          nodeSelector = local.infra_scheduling.nodeSelector
          tolerations  = local.infra_scheduling.tolerations
        }
      }
      thanosRuler = {
        thanosRulerSpec = {
          nodeSelector = local.infra_scheduling.nodeSelector
          tolerations  = local.infra_scheduling.tolerations
        }
      }
      grafana = {
        nodeSelector          = local.infra_scheduling.nodeSelector
        tolerations           = local.infra_scheduling.tolerations
        assertNoLeakedSecrets = false
        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hosts            = ["grafana.cloudaura.online"]
          tls = [{
            secretName = "grafana-tls"
            hosts      = ["grafana.cloudaura.online"]
          }]
          annotations = {
            "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
            "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
          }
        }
      }
      kube-state-metrics = {
        enabled      = true
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
      }
      prometheusNodeExporter = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
      }
      alertmanager = {
        alertmanagerSpec = {
          nodeSelector = local.infra_scheduling.nodeSelector
          tolerations  = local.infra_scheduling.tolerations
        }
      }
      prometheusOperator = {
        nodeSelector = local.infra_scheduling.nodeSelector
        tolerations  = local.infra_scheduling.tolerations
        admissionWebhooks = {
          patch = {
            nodeSelector = local.infra_scheduling.nodeSelector
            tolerations  = local.infra_scheduling.tolerations
          }
        }
      }
    }
  }
}
