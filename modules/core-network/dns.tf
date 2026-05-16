locals {
  vpn_domain = "vpn.${var.base_domain}"
  app_domain = "app.${var.base_domain}"
  db_domain  = "db.${var.base_domain}"
}

resource "aws_route53_zone" "internal" {
  name = var.base_domain

  vpc {
    vpc_id = module.spoke_vpcs["shared-services"].vpc_id
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-internal-zone"
  })
}

resource "aws_route53_zone_association" "app" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = module.spoke_vpcs["app"].vpc_id
}

resource "aws_route53_zone_association" "dmz" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = module.spoke_vpcs["dmz"].vpc_id
}

resource "aws_route53_zone_association" "ingress" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = module.spoke_vpcs["ingress"].vpc_id
}

resource "aws_route53_record" "db" {
  count = var.rds_address != null && var.rds_address != "" ? 1 : 0

  zone_id = aws_route53_zone.internal.zone_id
  name    = local.db_domain
  type    = "CNAME"
  ttl     = 300
  records = [var.rds_address]
}

resource "aws_route53_record" "app" {
  count = length(var.app_private_ips) > 0 ? length(var.app_private_ips) : 0

  zone_id = aws_route53_zone.internal.zone_id
  name    = local.app_domain
  type    = "A"
  ttl     = 300
  records = [var.app_private_ips[count.index]]

  set_identifier = "app-server-${count.index + 1}"
  weighted_routing_policy {
    weight = 50
  }
}
