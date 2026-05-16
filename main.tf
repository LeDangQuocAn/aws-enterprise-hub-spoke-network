module "core_network" {
  source = "./modules/core-network"

  project_name    = var.project_name
  environment     = var.environment
  tgw_description = var.tgw_description
  common_tags     = local.common_tags

  vpc_azs         = var.vpc_azs
  vpc_supernet    = var.vpc_supernet
  vpc_definitions = var.vpc_definitions
  base_domain     = var.base_domain
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  common_tags  = local.common_tags

  vpc_ids            = module.core_network.vpc_ids
  private_subnet_ids = module.core_network.private_subnet_ids
  vpc_supernet       = var.vpc_supernet
  base_domain        = var.base_domain

  ingress_cidr          = var.ingress_cidr
  dmz_cidr              = var.dmz_cidr
  app_cidr              = module.core_network.vpc_cidrs["app"]
  vpn_client_cidr       = var.vpn_client_cidr
  client_vpn_dns_server = var.client_vpn_dns_server

  depends_on = [module.core_network]
}

module "workloads" {
  source = "./modules/workloads"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags

  vpc_ids            = module.core_network.vpc_ids
  public_subnet_ids  = module.core_network.public_subnet_ids
  private_subnet_ids = module.core_network.private_subnet_ids

  ingress_alb_sg_id = module.security.ingress_alb_sg_id
  app_web_sg_id     = module.security.app_web_sg_id
  app_db_sg_id      = module.security.app_db_sg_id
  web_acl_arn       = module.security.web_acl_arn

  instance_type        = var.instance_type
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version    = var.db_engine_version
  db_username          = var.db_username
  db_password          = var.db_password

  depends_on = [module.core_network, module.security]
}
