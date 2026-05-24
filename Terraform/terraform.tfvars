"aws-load-balancer-controller" = {
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
      # Controller ke liye zaroori policy
      policy_arn      = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess" 
    }
    
    # Aapki di hui External Secrets ki configuration
    "external-secrets" = {
      namespace       = "kube-system"
      service_account = "external-secrets"
      policy_arn      = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
    }
  }
