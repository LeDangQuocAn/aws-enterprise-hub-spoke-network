locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Name        = local.name_prefix
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

resource "aws_ec2_transit_gateway" "core" {
  description                     = var.tgw_description
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  multicast_support               = "disable"
  vpn_ecmp_support                = "enable"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tgw"
  })
}
