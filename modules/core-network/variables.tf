variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "tgw_description" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_azs" {
  type = list(string)
}

variable "vpc_supernet" {
  type = string
}

variable "vpc_definitions" {
  type = map(object({
    vpc_newbits       = number
    vpc_netnum        = number
    workload_mode     = string
    workload_newbits  = number
    workload_netstart = number
  }))
}

variable "base_domain" {
  type = string
}

variable "rds_address" {
  type    = string
  default = null
}

variable "app_private_ips" {
  type    = list(string)
  default = []
}
