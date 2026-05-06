locals {
  vpc_azs      = ["ap-southeast-1a", "ap-southeast-1b"]
  vpc_supernet = "10.10.0.0/16"

  vpc_definitions = {
    ingress = {
      vpc_newbits       = 8
      vpc_netnum        = 0
      workload_mode     = "public"
      workload_newbits  = 2
      workload_netstart = 1
    }
    egress = {
      vpc_newbits       = 8
      vpc_netnum        = 1
      workload_mode     = "private"
      workload_newbits  = 2
      workload_netstart = 1
    }
    dmz = {
      vpc_newbits       = 8
      vpc_netnum        = 2
      workload_mode     = "public"
      workload_newbits  = 2
      workload_netstart = 1
    }
    shared-services = {
      vpc_newbits       = 6
      vpc_netnum        = 1
      workload_mode     = "private"
      workload_newbits  = 2
      workload_netstart = 1
    }
    app = {
      vpc_newbits       = 5
      vpc_netnum        = 1
      workload_mode     = "private"
      workload_newbits  = 3
      workload_netstart = 1
    }
  }

  vpc_with_cidr = {
    for vpc_name, cfg in local.vpc_definitions :
    vpc_name => merge(cfg, {
      cidr = cidrsubnet(local.vpc_supernet, cfg.vpc_newbits, cfg.vpc_netnum)
    })
  }

  vpc_with_subnets = {
    for vpc_name, cfg in local.vpc_with_cidr :
    vpc_name => merge(cfg, {
      workload_subnets = [
        for az_index in range(length(local.vpc_azs)) :
        cidrsubnet(cfg.cidr, cfg.workload_newbits, cfg.workload_netstart + az_index)
      ]
      tgw_subnets = [
        for az_index in range(length(local.vpc_azs)) :
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

module "spoke_vpcs" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  for_each = local.vpc_layout

  name = "${var.project_name}-${each.key}-vpc"
  cidr = each.value.cidr
  azs  = local.vpc_azs

  public_subnets  = each.value.public_subnets
  private_subnets = each.value.private_subnets
  intra_subnets   = each.value.tgw_subnets

  public_subnet_names = each.value.workload_mode == "public" ? [
    for az in local.vpc_azs :
    "${var.project_name}-${each.key}-public-${az}"
  ] : []

  private_subnet_names = each.value.workload_mode == "private" ? [
    for az in local.vpc_azs :
    "${var.project_name}-${each.key}-private-${az}"
  ] : []

  intra_subnet_names = [
    for az in local.vpc_azs :
    "${var.project_name}-${each.key}-tgw-${az}"
  ]

  create_igw              = false
  enable_nat_gateway      = false
  single_nat_gateway      = false
  one_nat_gateway_per_az  = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = each.value.workload_mode == "public"

  tags = merge(local.common_tags, {
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

  transit_gateway_id = var.tgw_id
  vpc_id             = module.spoke_vpcs[each.key].vpc_id
  subnet_ids         = module.spoke_vpcs[each.key].intra_subnets

  dns_support            = "enable"
  ipv6_support           = "disable"
  appliance_mode_support = "disable"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}-tgw-attachment"
  })
}

output "vpc_ids" {
  description = "Provisioned VPC IDs keyed by VPC name."
  value = {
    for vpc_name, mod in module.spoke_vpcs :
    vpc_name => mod.vpc_id
  }
}

output "tgw_subnet_ids" {
  description = "Dedicated TGW subnet IDs keyed by VPC name."
  value = {
    for vpc_name, mod in module.spoke_vpcs :
    vpc_name => mod.intra_subnets
  }
}

output "tgw_attachment_ids" {
  description = "Transit Gateway attachment IDs keyed by VPC name."
  value = {
    for vpc_name, attachment in aws_ec2_transit_gateway_vpc_attachment.vpc :
    vpc_name => attachment.id
  }
}
