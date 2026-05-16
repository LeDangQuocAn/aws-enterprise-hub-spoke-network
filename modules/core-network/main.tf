locals {
  name_prefix = "${var.project_name}-${var.environment}"

  vpc_with_cidr = {
    for vpc_name, cfg in var.vpc_definitions :
    vpc_name => merge(cfg, {
      cidr = cidrsubnet(var.vpc_supernet, cfg.vpc_newbits, cfg.vpc_netnum)
    })
  }

  vpc_with_subnets = {
    for vpc_name, cfg in local.vpc_with_cidr :
    vpc_name => merge(cfg, {
      workload_subnets = [
        for az_index in range(length(var.vpc_azs)) :
        cidrsubnet(cfg.cidr, cfg.workload_newbits, cfg.workload_netstart + az_index)
      ]
      tgw_subnets = [
        for az_index in range(length(var.vpc_azs)) :
        cidrsubnet(cfg.cidr, 28 - tonumber(split("/", cfg.cidr)[1]), az_index)
      ]
    })
  }

  vpc_layout = {
    for vpc_name, cfg in local.vpc_with_subnets :
    vpc_name => merge(cfg, {
      public_subnets  = cfg.workload_mode == "public" ? cfg.workload_subnets : []
      private_subnets = cfg.workload_mode == "private" ? cfg.workload_subnets : []
    })
  }
}

resource "aws_ec2_transit_gateway" "core" {
  description                     = var.tgw_description
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  multicast_support               = "disable"
  vpn_ecmp_support                = "enable"

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-tgw"
  })
}

module "spoke_vpcs" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  for_each = local.vpc_layout

  name = "${var.project_name}-${each.key}-vpc"
  cidr = each.value.cidr
  azs  = var.vpc_azs

  public_subnets  = each.value.public_subnets
  private_subnets = each.value.private_subnets
  intra_subnets   = each.value.tgw_subnets

  public_subnet_names = each.value.workload_mode == "public" ? [
    for az in var.vpc_azs :
    "${var.project_name}-${each.key}-public-${az}"
  ] : []

  private_subnet_names = each.value.workload_mode == "private" ? [
    for az in var.vpc_azs :
    "${var.project_name}-${each.key}-private-${az}"
  ] : []

  intra_subnet_names = [
    for az in var.vpc_azs :
    "${var.project_name}-${each.key}-tgw-${az}"
  ]

  create_igw                         = contains(["ingress", "egress"], each.key)
  enable_nat_gateway                 = false
  single_nat_gateway                 = false
  one_nat_gateway_per_az             = false
  create_multiple_intra_route_tables = true
  enable_dns_hostnames               = true
  enable_dns_support                 = true
  map_public_ip_on_launch            = each.value.workload_mode == "public"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${each.key}-vpc"
  })

  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }

  intra_subnet_tags = {
    Tier = "tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc" {
  for_each = local.vpc_layout

  transit_gateway_id = aws_ec2_transit_gateway.core.id
  vpc_id             = module.spoke_vpcs[each.key].vpc_id
  subnet_ids         = module.spoke_vpcs[each.key].intra_subnets

  dns_support            = "enable"
  ipv6_support           = "disable"
  appliance_mode_support = "disable"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${each.key}-tgw-attachment"
  })
}
