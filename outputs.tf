output "transit_gateway_id" {
  description = "ID of the core Transit Gateway."
  value       = module.core_network.tgw_id
}

output "transit_gateway_arn" {
  description = "ARN of the core Transit Gateway."
  value       = module.core_network.tgw_arn
}

output "ingress_alb_dns_name" {
  description = "DNS name of the Internet-facing ALB in Ingress VPC."
  value       = module.workloads.alb_dns_name
}

output "ingress_alb_arn" {
  description = "ARN of the Internet-facing ALB in Ingress VPC."
  value       = module.workloads.alb_arn
}

output "app_target_group_arn" {
  description = "ARN of the ALB Target Group for App VPC (target_type=ip)."
  value       = module.workloads.target_group_arn
}

output "rds_endpoint" {
  description = "RDS endpoint address for the App DB instance."
  value       = module.workloads.rds_endpoint
}

output "vpc_flow_logs_log_group_name" {
  description = "CloudWatch Log Group name for global VPC Flow Logs."
  value       = module.security.vpc_flow_logs_log_group_name
}

output "client_vpn_endpoint_id" {
  description = "ID of the AWS Client VPN endpoint for remote management."
  value       = module.security.client_vpn_endpoint_id
}

output "client_vpn_endpoint_dns_name" {
  description = "DNS name of the AWS Client VPN endpoint for remote management."
  value       = module.security.client_vpn_endpoint_dns_name
}

output "client_vpn_log_group_name" {
  description = "CloudWatch Log Group name for AWS Client VPN connection logs."
  value       = module.security.client_vpn_log_group_name
}

output "vpn_client_cert" {
  description = "PEM-encoded client certificate for AWS Client VPN."
  value       = module.security.vpn_client_cert
}

output "vpn_client_key" {
  description = "PEM-encoded private key for AWS Client VPN client authentication."
  value       = module.security.vpn_client_key
  sensitive   = true
}

output "vpn_root_ca" {
  description = "PEM-encoded root CA certificate for AWS Client VPN."
  value       = module.security.vpn_root_ca
}

output "app_instance_private_ips" {
  description = "Private IP addresses of App EC2 instances."
  value       = module.workloads.app_instance_private_ips
}

output "core_vpc_ids" {
  description = "Core network VPC IDs by VPC name."
  value       = module.core_network.vpc_ids
}

output "core_private_subnet_ids" {
  description = "Core network private subnet IDs by VPC name."
  value       = module.core_network.private_subnet_ids
}

output "core_public_subnet_ids" {
  description = "Core network public subnet IDs by VPC name."
  value       = module.core_network.public_subnet_ids
}

