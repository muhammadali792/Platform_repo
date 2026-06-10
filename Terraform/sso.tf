# ─────────────────────────────────────────────
# 1. SSO Instance Data
# ─────────────────────────────────────────────
data "aws_ssoadmin_instances" "main" {}

# ─────────────────────────────────────────────
# 2. ArgoCD SSO Application
# ─────────────────────────────────────────────
resource "aws_ssoadmin_application" "argocd" {
  name                     = "argocd"
  application_provider_arn = "arn:aws:sso::aws:applicationProvider/custom"
  instance_arn             = tolist(data.aws_ssoadmin_instances.main.arns)[0]

  portal_options {
    sign_in_options {
      application_url = "https://argocd.cloudaura.online"
      origin          = "APPLICATION"
    }
    visibility = "ENABLED"
  }

  status = "ENABLED"
}

# ─────────────────────────────────────────────
# 3. Grafana SSO Application
# ─────────────────────────────────────────────
resource "aws_ssoadmin_application" "grafana" {
  name                     = "grafana"
  application_provider_arn = "arn:aws:sso::aws:applicationProvider/custom"
  instance_arn             = tolist(data.aws_ssoadmin_instances.main.arns)[0]

  portal_options {
    sign_in_options {
      application_url = "https://grafana.cloudaura.online"
      origin          = "APPLICATION"
    }
    visibility = "ENABLED"
  }

  status = "ENABLED"
}

# ─────────────────────────────────────────────
# 4. ArgoCD OIDC Secret
# ─────────────────────────────────────────────
resource "aws_secretsmanager_secret" "argocd_oidc" {
  name                    = "argocd/oidc-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "argocd_oidc" {
  secret_id     = aws_secretsmanager_secret.argocd_oidc.id
  secret_string = jsonencode({
    oidc_client_secret = aws_ssoadmin_application.argocd.application_id
  })
}

# ─────────────────────────────────────────────
# 5. Grafana OIDC Secret
# ─────────────────────────────────────────────
resource "aws_secretsmanager_secret" "grafana_oidc" {
  name                    = "grafana/oidc-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "grafana_oidc" {
  secret_id     = aws_secretsmanager_secret.grafana_oidc.id
  secret_string = jsonencode({
    oidc_client_secret = aws_ssoadmin_application.grafana.application_id
  })
}

# ─────────────────────────────────────────────
# 6. ArgoCD Helm SSO Update
# ─────────────────────────────────────────────
resource "helm_release" "argocd_sso" {
  name         = "argo-cd"
  chart        = "argo-cd"
  repository   = "https://argoproj.github.io/argo-helm"
  namespace    = "argocd"
  reuse_values = true

  values = [yamlencode({
    server = {
      config = {
        "oidc.config" = yamlencode({
          name         = "AWS SSO"
          issuer       = "https://identitycenter.amazonaws.com/ssooidc/${tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]}"
          clientID     = aws_ssoadmin_application.argocd.application_id
          clientSecret = "$oidc.clientSecret"
          requestedScopes = ["openid", "profile", "email"]
          requestedIDTokenClaims = {
            groups = { essential = true }
          }
        })
      }
      rbacConfig = {
        "policy.default" = "role:readonly"
        "policy.csv"     = "g, DevOps, role:admin\ng, Developers, role:readonly"
      }
    }
  })]

  depends_on = [
    helm_release.argo_cd,
    aws_ssoadmin_application.argocd
  ]
}

# ─────────────────────────────────────────────
# 7. Grafana Helm SSO Update
# ─────────────────────────────────────────────
resource "helm_release" "grafana_sso" {
  name         = "kube-prometheus-stack"
  chart        = "kube-prometheus-stack"
  repository   = "https://prometheus-community.github.io/helm-charts"
  namespace    = "kube-prometheus-stack"
  reuse_values = true

  values = [yamlencode({
    grafana = {
      grafana_ini = {
        auth_generic_oauth = {
          enabled             = true
          name                = "AWS SSO"
          client_id           = aws_ssoadmin_application.grafana.application_id
          client_secret       = "$__secretsmanager:grafana/oidc-secret:oidc_client_secret"
          scopes              = "openid profile email"
          auth_url            = "https://identitycenter.amazonaws.com/ssooidc/${tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]}/authorize"
          token_url           = "https://identitycenter.amazonaws.com/ssooidc/${tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]}/token"
          api_url             = "https://identitycenter.amazonaws.com/ssooidc/${tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]}/userinfo"
          allow_sign_up       = true
          role_attribute_path = "contains(groups[*], 'DevOps') && 'Admin' || 'Viewer'"
        }
      }
    }
  })]

  depends_on = [
    helm_release.kube_prometheus_stack,
    aws_ssoadmin_application.grafana
  ]
}
