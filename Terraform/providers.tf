terraform {
  required_version = ">= 1.7.0" # Modern Terraform engine for K8s 1.35+
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50" # Latest AWS SDK
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31" # Latest K8s client for 1.35 structure
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15" 
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14" # Stable wrapper for raw manifests
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}
