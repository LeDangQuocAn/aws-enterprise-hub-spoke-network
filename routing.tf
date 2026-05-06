# Manual NAT for centralized egress

resource "aws_eip" "egress_nat" {
  count  = length(local.vpc_azs)
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-egress-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "egress" {
  count = length(local.vpc_azs)

  allocation_id = aws_eip.egress_nat[count.index].id
  subnet_id     = module.spoke_vpcs["egress"].public_subnets[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-egress-nat-${count.index + 1}"
  })

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.vpc]
}

# VPC Routes to Transit Gateway
# Routes for App, Shared-Services, and DMZ to send 0.0.0.0/0 to TGW (from private route tables)

resource "aws_route" "vpc_to_tgw_internet" {
  for_each = {
    for vpc_name in ["app", "shared-services", "dmz"] :
    vpc_name => {
      route_table_id = module.spoke_vpcs[vpc_name].private_route_table_ids[0]
    }
  }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.core.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.vpc]
}

# Return Routes for Ingress and Egress
# Routes for Ingress and Egress to send 10.10.0.0/16 (internal network) to TGW

resource "aws_route" "vpc_to_tgw_internal" {
  for_each = {
    for vpc_name in ["ingress", "egress"] :
    vpc_name => {
      route_table_id = module.spoke_vpcs[vpc_name].public_route_table_ids[0]
    }
  }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = "10.10.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.core.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.vpc]
}

# Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route_table" "core" {
  transit_gateway_id = aws_ec2_transit_gateway.core.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-tgw-rt"
  })
}

# Transit Gateway Associations and Propagations
resource "aws_ec2_transit_gateway_route_table_association" "vpc" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.vpc

  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpc" {
  for_each = aws_ec2_transit_gateway_vpc_attachment.vpc

  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id

  depends_on = [aws_ec2_transit_gateway_route_table_association.vpc]
}

# Egress TGW subnet routes to per-AZ NAT gateways
resource "aws_route" "egress_intra_to_nat" {
  count = length(local.vpc_azs)

  route_table_id         = module.spoke_vpcs["egress"].intra_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.egress[count.index].id

  depends_on = [aws_nat_gateway.egress]
}

# Static Route: 0.0.0.0/0 to Egress VPC Attachment
resource "aws_ec2_transit_gateway_route" "default_to_egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc["egress"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
  blackhole                      = false

  depends_on = [aws_ec2_transit_gateway_route_table_propagation.vpc]
}

# Outputs for Routing Validation
output "tgw_route_table_id" {
  description = "Transit Gateway Route Table ID."
  value       = aws_ec2_transit_gateway_route_table.core.id
}

output "tgw_route_table_associations" {
  description = "TGW Route Table associations by VPC name."
  value = {
    for vpc_name, assoc in aws_ec2_transit_gateway_route_table_association.vpc :
    vpc_name => assoc.id
  }
}

output "tgw_route_table_propagations" {
  description = "TGW Route Table propagations by VPC name."
  value = {
    for vpc_name, prop in aws_ec2_transit_gateway_route_table_propagation.vpc :
    vpc_name => prop.id
  }
}
