output "ingress_alb_sg_id" {
  value = aws_security_group.ingress_alb_sg.id
}

output "app_web_sg_id" {
  value = aws_security_group.app_web_sg.id
}

output "app_db_sg_id" {
  value = aws_security_group.app_db_sg.id
}

output "dmz_ssm_sg_id" {
  value = aws_security_group.dmz_ssm_sg.id
}

output "client_vpn_sg_id" {
  value = aws_security_group.client_vpn.id
}

output "web_acl_arn" {
  value = aws_wafv2_web_acl.ingress.arn
}

output "vpc_flow_logs_log_group_name" {
  value = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.remote_mgmt.id
}

output "client_vpn_endpoint_dns_name" {
  value = aws_ec2_client_vpn_endpoint.remote_mgmt.dns_name
}

output "client_vpn_log_group_name" {
  value = aws_cloudwatch_log_group.client_vpn.name
}

output "vpn_client_cert" {
  value = tls_locally_signed_cert.client_vpn_client.cert_pem
}

output "vpn_client_key" {
  value     = tls_private_key.client_vpn_client.private_key_pem
  sensitive = true
}

output "vpn_root_ca" {
  value = tls_self_signed_cert.client_vpn_root_ca.cert_pem
}
