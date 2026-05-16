variable "aws_region" {
  description = "AWS region where the hub Transit Gateway is created."
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "sprint1"
}

variable "project_name" {
  description = "Project name used in tags and resource naming."
  type        = string
  default     = "aws-enterprise-hub-spoke-network"
}

variable "owner" {
  description = "Owner tag for enterprise accountability."
  type        = string
  default     = "group-9"
}

variable "cost_center" {
  description = "Optional cost center tag."
  type        = string
  default     = "network-design"
}

variable "additional_tags" {
  description = "Additional tags to merge with the standard tag set."
  type        = map(string)
  default     = {}
}

variable "tgw_description" {
  description = "Optional Transit Gateway description."
  type        = string
  default     = "Core hub Transit Gateway for the university enterprise network"
}

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "eduadmin"
}

variable "db_password" {
  description = "Master password for the RDS instance. Keep this secret; override via tfvars or environment."
  type        = string
  sensitive   = true
}

variable "vpn_client_cidr" {
  description = "CIDR block allocated for Client VPN clients (supernet)."
  type        = string
  default     = "172.16.0.0/22"
}

variable "dmz_cidr" {
  description = "CIDR block used by the DMZ VPC."
  type        = string
  default     = "10.10.2.0/24"
}

variable "ingress_cidr" {
  description = "CIDR block used by the Ingress/ALB VPC."
  type        = string
  default     = "10.10.0.0/24"
}

variable "instance_type" {
  description = "Default EC2 instance type for application servers."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class for the application database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage (GB) for the RDS instance."
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Major engine version for RDS (e.g. MySQL 8.0)."
  type        = string
  default     = "8.0"
}

variable "base_domain" {
  description = "Base internal domain used for private Route53 records."
  type        = string
  default     = "educloud.internal"
}

variable "client_vpn_dns_server" {
  description = "DNS server IP advertised to Client VPN clients."
  type        = string
  default     = "10.10.0.2"
}

variable "vpc_azs" {
  description = "Availability zones used for all spoke VPCs."
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "vpc_supernet" {
  description = "Supernet used to derive all spoke VPC CIDRs."
  type        = string
  default     = "10.10.0.0/16"
}

variable "vpc_definitions" {
  description = "Spoke VPC subnetting and workload layout definitions."
  type = map(object({
    vpc_newbits       = number
    vpc_netnum        = number
    workload_mode     = string
    workload_newbits  = number
    workload_netstart = number
  }))

  default = {
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
      workload_mode     = "public"
      workload_newbits  = 2
      workload_netstart = 1
    }
    dmz = {
      vpc_newbits       = 8
      vpc_netnum        = 2
      workload_mode     = "private"
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
}
