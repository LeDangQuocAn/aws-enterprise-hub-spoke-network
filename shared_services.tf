# Shared Services: Internal DNS using Route 53 Private Hosted Zone

resource "aws_route53_zone" "internal" {
  name = "educloud.internal"

  vpc {
    vpc_id = module.spoke_vpcs["shared-services"].vpc_id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-internal-zone"
  })
}

# Associate the private zone with App VPC
resource "aws_route53_zone_association" "app" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = module.spoke_vpcs["app"].vpc_id
}

# Associate the private zone with DMZ VPC
resource "aws_route53_zone_association" "dmz" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = module.spoke_vpcs["dmz"].vpc_id
}

# Associate the private zone with Ingress VPC
resource "aws_route53_zone_association" "ingress" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = module.spoke_vpcs["ingress"].vpc_id
}

# Internal DNS Record: Database
# CNAME pointing to RDS endpoint address
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "db.educloud.internal"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.app_db.address]
}

# Internal DNS Records: Application Tier (Weighted routing for load distribution)
# First app instance
resource "aws_route53_record" "app_server_1" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "app.educloud.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.app_servers[0].private_ip]

  set_identifier = "app-server-1-az-a"
  weighted_routing_policy {
    weight = 50
  }
}

# Second app instance
resource "aws_route53_record" "app_server_2" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "app.educloud.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.app_servers[1].private_ip]

  set_identifier = "app-server-2-az-b"
  weighted_routing_policy {
    weight = 50
  }
}

# Outputs for DNS validation
output "route53_zone_id" {
  description = "ID of the internal Route 53 private hosted zone (educloud.internal)."
  value       = aws_route53_zone.internal.zone_id
}

output "route53_nameservers" {
  description = "Route 53 nameservers for the internal hosted zone."
  value       = aws_route53_zone.internal.name_servers
}

output "route53_db_record" {
  description = "Internal DNS CNAME record for database (db.educloud.internal)."
  value       = aws_route53_record.db.fqdn
}

output "route53_app_record" {
  description = "Internal DNS A record for application tier (app.educloud.internal)."
  value       = aws_route53_record.app_server_1.fqdn
}
