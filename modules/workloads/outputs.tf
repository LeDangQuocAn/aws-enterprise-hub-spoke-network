output "alb_dns_name" {
  value = aws_lb.ingress_alb.dns_name
}

output "alb_arn" {
  value = aws_lb.ingress_alb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.app_targets.arn
}

output "rds_endpoint" {
  value = aws_db_instance.app_db.endpoint
}

output "rds_address" {
  value = aws_db_instance.app_db.address
}

output "app_instance_profile_arn" {
  value = aws_iam_instance_profile.app_ec2_profile.arn
}

output "app_instance_profile_name" {
  value = aws_iam_instance_profile.app_ec2_profile.name
}

output "app_instance_private_ips" {
  value = [for instance in aws_instance.app_servers : instance.private_ip]
}
