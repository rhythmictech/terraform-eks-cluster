output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_id" {
  value = module.eks.cluster_id
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "worker_iam_role_arn" {
  value = aws_iam_role.worker_role.arn
}

output "worker_iam_role_name" {
  value = aws_iam_role.worker_role.name
}
