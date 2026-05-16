output "tgw_id" {
  value = aws_ec2_transit_gateway.core.id
}

output "tgw_arn" {
  value = aws_ec2_transit_gateway.core.arn
}

output "tgw_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.core.id
}

output "vpc_ids" {
  value = {
    for vpc_name, mod in module.spoke_vpcs :
    vpc_name => mod.vpc_id
  }
}

output "vpc_cidrs" {
  value = {
    for vpc_name, cfg in local.vpc_layout :
    vpc_name => cfg.cidr
  }
}

output "public_subnet_ids" {
  value = {
    for vpc_name, mod in module.spoke_vpcs :
    vpc_name => mod.public_subnets
  }
}

output "private_subnet_ids" {
  value = {
    for vpc_name, mod in module.spoke_vpcs :
    vpc_name => mod.private_subnets
  }
}

output "intra_subnet_ids" {
  value = {
    for vpc_name, mod in module.spoke_vpcs :
    vpc_name => mod.intra_subnets
  }
}

output "route53_zone_id" {
  value = aws_route53_zone.internal.zone_id
}

output "route53_db_record" {
  value = length(aws_route53_record.db) > 0 ? aws_route53_record.db[0].fqdn : null
}

output "route53_app_record" {
  value = length(aws_route53_record.app) > 0 ? aws_route53_record.app[0].fqdn : null
}
