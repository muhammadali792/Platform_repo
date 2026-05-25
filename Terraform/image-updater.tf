# 2. Helm Release configuration
resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = false

  values = [
    <<EOF
serviceAccount:
  create: true
  name: "argocd-image-updater-sa"

# Node Selection: Pod sirf system nodes par chalega
nodeSelector:
  role: system

# Tolerations: Critical nodes ke taints ko bypass karne ke liye
tolerations:
  - key: "CriticalAddonsOnly"
    operator: "Exists"
    effect: "NoSchedule"
  - key: "role"
    operator: "Equal"
    value: "system"
    effect: "NoSchedule"

config:
  registries:
    - name: ECR
      api_url: https://${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
      credsexpire: 0
EOF
  ]

  # Ye ensure karta hai ke Pod Identity link pehle ban jaye
  depends_on = [
    aws_eks_pod_identity_association.addon_associations
  ]
}
