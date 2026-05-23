resource "aws_security_group" "additional_node_sg" {
  name        = "cloudaura-${var.environment}-node-additional-sg"
  description = "Additional security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  # =============================================================================
  # 1. NODE-TO-NODE INTERNAL TRAFFIC
  # =============================================================================
  ingress {
    description = "Allow all internal traffic between nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # =============================================================================
  # 2. INBOUND TRAFFIC FROM NLB (Public Subnets)
  # =============================================================================
  ingress {
    description = "HTTP traffic from NLB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }

  ingress {
    description = "HTTPS traffic from NLB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }

  ingress {
    description = "NGINX health check from NLB"
    from_port   = 10254
    to_port     = 10254
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }

  # =============================================================================
  # 3. NLB TO PODS — IP TARGET MODE
  # NLB seedha pod IP pe traffic bhejta hai VPC ke andar
  # =============================================================================
  ingress {
    description = "NLB to pods direct traffic via ip target mode"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # =============================================================================
  # 4. KUBELET API
  # =============================================================================
  ingress {
    description = "Kubelet API for control plane communication"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # =============================================================================
  # 5. EGRESS
  # =============================================================================
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment              = var.environment
    Name                     = "cloudaura-${var.environment}-node-additional-sg"
    "karpenter.sh/discovery" = var.cluster_name
  }
}
