variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_ids" {
  type = map(string)
}

variable "private_subnet_ids" {
  type = map(list(string))
}

variable "vpc_supernet" {
  type = string
}

variable "base_domain" {
  type = string
}

variable "ingress_cidr" {
  type = string
}

variable "dmz_cidr" {
  type = string
}

variable "app_cidr" {
  type = string
}

variable "vpn_client_cidr" {
  type = string
}

variable "client_vpn_dns_server" {
  type = string
}
