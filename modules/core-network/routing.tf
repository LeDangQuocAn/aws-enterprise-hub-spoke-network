locals {
  private_route_tables_to_tgw = merge([
    for vpc_name in ["app", "dmz", "shared-services"] : {
      for az_index in range(length(var.vpc_azs)) :
      "${vpc_name}-az${az_index}" => {
        vpc_name = vpc_name
        az_index = az_index
      }
    }
  ]...)
}

resource "aws_eip" "egress_nat" {
  count  = length(var.vpc_azs)
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-egress-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "egress" {
  count = length(var.vpc_azs)

  allocation_id = aws_eip.egress_nat[count.index].id
  subnet_id     = module.spoke_vpcs["egress"].public_subnets[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-egress-nat-${count.index + 1}"
  })

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.vpc]
}

resource "aws_route" "vpc_to_tgw_internet" {
  for_each = local.private_route_tables_to_tgw

  route_table_id         = module.spoke_vpcs[each.value.vpc_name].private_route_table_ids[each.value.az_index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.core.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.vpc]
}

resource "aws_route" "vpc_to_tgw_internal" {
  for_each = {
    for vpc_name in ["ingress", "egress"] :
    vpc_name => {
      route_table_id = module.spoke_vpcs[vpc_name].public_route_table_ids[0]
    }
  }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = var.vpc_supernet
  transit_gateway_id     = aws_ec2_transit_gateway.core.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.vpc]
}

resource "aws_ec2_transit_gateway_route_table" "core" {
  transit_gateway_id = aws_ec2_transit_gateway.core.id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-tgw-rt"
  })
}

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

resource "aws_route" "egress_intra_to_nat" {
  count = length(var.vpc_azs)

  route_table_id         = module.spoke_vpcs["egress"].intra_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.egress[count.index].id

  depends_on = [aws_nat_gateway.egress]
}

resource "aws_ec2_transit_gateway_route" "default_to_egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc["egress"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
  blackhole                      = false

  depends_on = [aws_ec2_transit_gateway_route_table_propagation.vpc]
}
