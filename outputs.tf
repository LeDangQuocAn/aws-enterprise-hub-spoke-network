output "transit_gateway_id" {
  description = "ID of the core Transit Gateway."
  value       = aws_ec2_transit_gateway.core.id
}

output "transit_gateway_arn" {
  description = "ARN of the core Transit Gateway."
  value       = aws_ec2_transit_gateway.core.arn
}

output "transit_gateway_owner_id" {
  description = "AWS account ID that owns the Transit Gateway."
  value       = aws_ec2_transit_gateway.core.owner_id
}

output "transit_gateway_default_route_table_association" {
  description = "Default association setting for the Transit Gateway."
  value       = aws_ec2_transit_gateway.core.default_route_table_association
}

output "transit_gateway_default_route_table_propagation" {
  description = "Default propagation setting for the Transit Gateway."
  value       = aws_ec2_transit_gateway.core.default_route_table_propagation
}

output "app_instance_profile_arn" {
  description = "ARN of the IAM instance profile for App EC2 instances."
  value       = aws_iam_instance_profile.app_ec2_profile.arn
}

output "app_instance_profile_name" {
  description = "Name of the IAM instance profile for App EC2 instances."
  value       = aws_iam_instance_profile.app_ec2_profile.name
}

output "ingress_alb_dns_name" {
  description = "DNS name of the Internet-facing ALB in Ingress VPC."
  value       = aws_lb.ingress_alb.dns_name
}

output "ingress_alb_arn" {
  description = "ARN of the Internet-facing ALB in Ingress VPC."
  value       = aws_lb.ingress_alb.arn
}

output "app_target_group_arn" {
  description = "ARN of the ALB Target Group for App VPC (target_type=ip)."
  value       = aws_lb_target_group.app_targets.arn
}

output "rds_endpoint" {
  description = "RDS endpoint address for the App DB instance."
  value       = aws_db_instance.app_db.endpoint
}

output "vpc_flow_logs_log_group_name" {
  description = "CloudWatch Log Group name for global VPC Flow Logs."
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "client_vpn_endpoint_id" {
  description = "ID of the AWS Client VPN endpoint for remote management."
  value       = aws_ec2_client_vpn_endpoint.remote_mgmt.id
}

output "client_vpn_endpoint_dns_name" {
  description = "DNS name of the AWS Client VPN endpoint for remote management."
  value       = aws_ec2_client_vpn_endpoint.remote_mgmt.dns_name
}

output "client_vpn_log_group_name" {
  description = "CloudWatch Log Group name for AWS Client VPN connection logs."
  value       = aws_cloudwatch_log_group.client_vpn.name
}

output "vpn_client_cert" {
  description = "PEM-encoded client certificate for AWS Client VPN."
  value       = tls_locally_signed_cert.client_vpn_client.cert_pem
}

output "vpn_client_key" {
  description = "PEM-encoded private key for AWS Client VPN client authentication."
  value       = tls_private_key.client_vpn_client.private_key_pem
  sensitive   = true
}

output "vpn_root_ca" {
  description = "PEM-encoded root CA certificate for AWS Client VPN."
  value       = tls_self_signed_cert.client_vpn_root_ca.cert_pem
}

output "app_instance_private_ips" {
  description = "Mapping of App EC2 instance IDs to private IP addresses."
  value = {
    for instance in aws_instance.app_servers :
    instance.id => instance.private_ip
  }
}

