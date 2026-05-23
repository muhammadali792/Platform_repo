module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8" 

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  # 🟢 Bilkul simple aur clear AZ selection (Slice hata diya)
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "karpenter.sh/discovery"                    = var.cluster_name 
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}
