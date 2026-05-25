locals {
  app_values = {
    # ArgoCD ke liye specific component keys
    argocd = {
      server       = { nodeSelector = { "role" = "system" }, tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }] }
      controller   = { nodeSelector = { "role" = "system" }, tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }] }
      repoServer   = { nodeSelector = { "role" = "system" }, tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }] }
      applicationSet = { nodeSelector = { "role" = "system" }, tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }] }
    }
    # Rollouts ke liye
    argo_rollouts = {
      controller = { nodeSelector = { "role" = "system" }, tolerations = [{ key = "CriticalAddonsOnly", operator = "Equal", value = "true", effect = "NoSchedule" }] }
    }
  }
}

# Helm Resources
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = "argocd"
  create_namespace = true
  values     = [yamlencode(local.app_values.argocd)]
}

resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  chart      = "argo-rollouts"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = "argocd"
  values     = [yamlencode(local.app_values.argo_rollouts)]
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = "kube-prometheus-stack"
  create_namespace = true
  values     = [yamlencode(local.app_values.prometheus)]
}
