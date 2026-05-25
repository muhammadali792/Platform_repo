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

# Node Selection aur Toleration settings
nodeSelector:
  role: system

tolerations:
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

  depends_on = [
    aws_eks_pod_identity_association.addon_associations
  ]
}
