resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.20.2" # 🟢 Artifact Hub ke mutabik naya stable version
  namespace        = "cert-manager"
  create_namespace = true

  values = [<<-EOT
    crds:
      enabled: true # 🟢 Naye cert-manager versions mein installCRDs ki jagah crds.enabled use hota hai
    global:
      nodeSelector:
        role: system
      tolerations:
      - key: "role"
        operator: "Equal"
        value: "system"
        effect: "NoSchedule"
  EOT
  ]

  depends_on = [module.eks]
}

resource "helm_release" "cert_manager_duckdns" {
  name       = "cert-manager-webhook-duckdns"
  repository = "https://ebrianne.github.io/helm-charts" # 🟢 Official active working repo URL
  chart      = "cert-manager-webhook-duckdns"
  version    = "0.1.2" # 🟢 Is repo ka working stable version
  namespace  = "cert-manager"

  values = [<<-EOT
    certManager:
      namespace: cert-manager
    clusterIssuer:
      production:
        enabled: false # Hum ne niche custom ClusterIssuer khud banaya hua hai isliye ise false rakha hai
    nodeSelector:
      role: system
    tolerations:
    - key: "role"
      operator: "Equal"
      value: "system"
      effect: "NoSchedule"
  EOT
  ]

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "duckdns_secret" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: duckdns-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  token: "896a3c54-360c-4a20-8d25-e421eeccf181"
YAML

  depends_on = [helm_release.cert_manager_duckdns]
}

resource "kubectl_manifest" "letsencrypt_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-duckdns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: muhammadali792@gmail.com
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
    - dns01:
        webhook:
          groupName: acme.webhook.duckdns.org
          solverName: duckdns
          config:
            secretRef:
              name: duckdns-token-secret
              key: token
YAML

  depends_on = [kubectl_manifest.duckdns_secret]
}
