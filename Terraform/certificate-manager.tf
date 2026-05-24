# 1. Cert-Manager (Helm se install hoga)
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.20.2"
  namespace        = "cert-manager"
  create_namespace = true
  timeout          = 600

  values = [<<-EOT
    crds:
      enabled: true
    nodeSelector:
      role: system
    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
  EOT
  ]
  depends_on = [module.eks]
}

# 2. DuckDNS Secret
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
  depends_on = [helm_release.cert_manager]
}

# 3. DuckDNS Webhook (Direct Manifest - No Repository Needed)
resource "kubectl_manifest" "cert_manager_webhook_duckdns" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cert-manager-webhook-duckdns
  namespace: cert-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cert-manager-webhook-duckdns
  template:
    metadata:
      labels:
        app: cert-manager-webhook-duckdns
    spec:
      nodeSelector:
        role: system
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Equal"
          value: "true"
          effect: "NoSchedule"
      containers:
        - name: webhook
          image: ebrianne/cert-manager-webhook-duckdns:0.1.2
          args:
            - --tls-cert-dir=/tls
            - --groupName=acme.webhook.duckdns.org
          ports:
            - containerPort: 443
YAML
  depends_on = [kubectl_manifest.duckdns_secret]
}

# 4. ClusterIssuer
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
  depends_on = [kubectl_manifest.cert_manager_webhook_duckdns]
}
