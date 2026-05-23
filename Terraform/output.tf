output "configure_kubectl" {
  description = "kubectl configure karne ka command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}
