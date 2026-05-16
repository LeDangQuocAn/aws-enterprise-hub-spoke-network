locals {
  vpn_domain = "vpn.${var.base_domain}"

  client_vpn_dmz_private_subnets = {
    for az_index in range(length(var.private_subnet_ids["dmz"])) :
    "dmz-az${az_index}" => az_index
  }
}

resource "aws_cloudwatch_log_group" "client_vpn" {
  name              = "/aws/vpn/client-vpn/${local.name_prefix}"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "/aws/vpn/client-vpn/${local.name_prefix}"
  })
}

resource "tls_private_key" "client_vpn_root_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "client_vpn_root_ca" {
  private_key_pem       = tls_private_key.client_vpn_root_ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87600
  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
  set_subject_key_id   = true
  set_authority_key_id = true

  subject {
    common_name  = "${local.name_prefix}-client-vpn-root-ca"
    organization = var.project_name
  }
}

resource "tls_private_key" "client_vpn_server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_vpn_server" {
  private_key_pem = tls_private_key.client_vpn_server.private_key_pem

  subject {
    common_name  = local.vpn_domain
    organization = var.project_name
  }
  dns_names = [local.vpn_domain]
}

resource "tls_locally_signed_cert" "client_vpn_server" {
  cert_request_pem      = tls_cert_request.client_vpn_server.cert_request_pem
  ca_private_key_pem    = tls_private_key.client_vpn_root_ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.client_vpn_root_ca.cert_pem
  validity_period_hours = 8760
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

resource "tls_private_key" "client_vpn_client" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_vpn_client" {
  private_key_pem = tls_private_key.client_vpn_client.private_key_pem

  subject {
    common_name  = "${local.name_prefix}-client-vpn-client"
    organization = var.project_name
  }
}

resource "tls_locally_signed_cert" "client_vpn_client" {
  cert_request_pem      = tls_cert_request.client_vpn_client.cert_request_pem
  ca_private_key_pem    = tls_private_key.client_vpn_root_ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.client_vpn_root_ca.cert_pem
  validity_period_hours = 8760
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth",
  ]
}

resource "aws_acm_certificate" "client_vpn_root_ca" {
  private_key      = tls_private_key.client_vpn_root_ca.private_key_pem
  certificate_body = tls_self_signed_cert.client_vpn_root_ca.cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-client-vpn-root-ca"
  })
}

resource "aws_acm_certificate" "client_vpn_server" {
  private_key      = tls_private_key.client_vpn_server.private_key_pem
  certificate_body = tls_locally_signed_cert.client_vpn_server.cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-client-vpn-server"
  })
}

resource "aws_acm_certificate" "client_vpn_client" {
  private_key      = tls_private_key.client_vpn_client.private_key_pem
  certificate_body = tls_locally_signed_cert.client_vpn_client.cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-client-vpn-client"
  })
}

resource "aws_security_group" "client_vpn" {
  name        = "${local.name_prefix}-client-vpn-sg"
  description = "Security group for AWS Client VPN endpoint"
  vpc_id      = var.vpc_ids["dmz"]

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow TLS client VPN traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow UDP client VPN traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-client-vpn-sg"
  })
}

resource "aws_ec2_client_vpn_endpoint" "remote_mgmt" {
  description            = "Client VPN endpoint for remote management access"
  server_certificate_arn = aws_acm_certificate.client_vpn_server.arn
  client_cidr_block      = var.vpn_client_cidr
  split_tunnel           = true
  dns_servers            = [var.client_vpn_dns_server]
  transport_protocol     = "udp"
  vpc_id                 = var.vpc_ids["dmz"]
  security_group_ids     = [aws_security_group.client_vpn.id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client_vpn_root_ca.arn
  }

  connection_log_options {
    enabled              = true
    cloudwatch_log_group = aws_cloudwatch_log_group.client_vpn.name
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-client-vpn"
  })
}

resource "aws_ec2_client_vpn_network_association" "dmz" {
  for_each = local.client_vpn_dmz_private_subnets

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.remote_mgmt.id
  subnet_id              = var.private_subnet_ids["dmz"][each.value]
}

resource "aws_ec2_client_vpn_route" "internal" {
  for_each = local.client_vpn_dmz_private_subnets

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.remote_mgmt.id
  destination_cidr_block = var.vpc_supernet
  target_vpc_subnet_id   = var.private_subnet_ids["dmz"][each.value]

  depends_on = [aws_ec2_client_vpn_network_association.dmz]
}

resource "aws_ec2_client_vpn_authorization_rule" "internal" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.remote_mgmt.id
  target_network_cidr    = var.vpc_supernet
  authorize_all_groups   = true

  depends_on = [aws_ec2_client_vpn_network_association.dmz]
}
