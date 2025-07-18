output "rubrik_cloud_cluster_ip_addresses" {
  value = local.cluster_node_ips
}

output "rubrik_hosts_sg_id" {
  value = module.rubrik_hosts_sg.security_group_id
}

output "s3_bucket" {
  value = aws_s3_bucket.cces-s3-bucket.id
}

output "secrets_manager_private_key_name" {
  value = "${var.cluster_name}-private-key"
}

output "aws_region" {
  value = data.aws_region.current.id
  description = "The AWS region where resources are deployed"
}

output "secrets_manager_get_ssh_key_command" {
  value = "aws secretsmanager get-secret-value --region ${data.aws_region.current.id} --secret-id ${var.cluster_name}-private-key --query SecretString --output text"
  description = "AWS CLI command to retrieve the SSH private key. The region is automatically detected from the AWS provider configuration."
}
