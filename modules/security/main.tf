locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_security_group" "ingress_alb_sg" {
  name        = "${var.project_name}-ingress-alb-sg"
  description = "Security group for ALB in Ingress VPC"
  vpc_id      = var.vpc_ids["ingress"]

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ingress-alb-sg"
  })
}

resource "aws_security_group" "app_web_sg" {
  name        = "${var.project_name}-app-web-sg"
  description = "Security group for web tier in App VPC"
  vpc_id      = var.vpc_ids["app"]

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr]
    description = "Allow HTTP from Ingress VPC"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr]
    description = "Allow HTTPS from Ingress VPC"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.dmz_cidr]
    description = "Allow ICMP from DMZ VPC"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.dmz_cidr]
    description = "Allow HTTP from DMZ VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-web-sg"
  })
}

resource "aws_security_group" "app_db_sg" {
  name        = "${var.project_name}-app-db-sg"
  description = "Security group for database tier in App VPC"
  vpc_id      = var.vpc_ids["app"]

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.app_cidr]
    description = "Allow MySQL from App VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-db-sg"
  })
}

resource "aws_security_group" "dmz_ssm_sg" {
  name        = "${var.project_name}-dmz-ssm-sg"
  description = "Security group for SSM endpoints and control plane in DMZ VPC"
  vpc_id      = var.vpc_ids["dmz"]

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.dmz_cidr]
    description = "Allow HTTPS for SSM Session Manager and control plane"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpn_client_cidr]
    description = "Allow HTTPS from Client VPN"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dmz-ssm-sg"
  })
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_ids["dmz"]
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids["dmz"]
  security_group_ids  = [aws_security_group.dmz_ssm_sg.id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dmz-ssm-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_ids["dmz"]
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids["dmz"]
  security_group_ids  = [aws_security_group.dmz_ssm_sg.id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dmz-ssmmessages-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_ids["dmz"]
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids["dmz"]
  security_group_ids  = [aws_security_group.dmz_ssm_sg.id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dmz-ec2messages-endpoint"
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/enterprise-flow-logs"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "/aws/vpc/enterprise-flow-logs"
  })
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs_role" {
  name               = "${local.name_prefix}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-flow-logs-role"
  })
}

data "aws_iam_policy_document" "flow_logs_write" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs_write" {
  name   = "${local.name_prefix}-flow-logs-write"
  role   = aws_iam_role.flow_logs_role.id
  policy = data.aws_iam_policy_document.flow_logs_write.json
}

resource "aws_flow_log" "vpc" {
  for_each = var.vpc_ids

  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
  traffic_type         = "ALL"
  vpc_id               = each.value

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-${each.key}-flow-logs"
  })
}
