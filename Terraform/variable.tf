variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "cluster_name" {
  type    = string
  default = "staging-cluster"
}

variable "cluster_version" {
  type    = string
  default = "1.35" # 🟢 Set to Kubernetes Latest v1.35
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "duckdns_domain" {
  type    = string
  default = "cloudaura.duckdns.org"
}
