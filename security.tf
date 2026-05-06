# Security Groups for Defense-in-Depth

# Ingress VPC: ALB Security Group
# Allows public HTTP/HTTPS traffic from internet
resource "aws_security_group" "ingress_alb_sg" {
  name        = "${var.project_name}-ingress-alb-sg"
  description = "Security group for ALB in Ingress VPC"
  vpc_id      = module.spoke_vpcs["ingress"].vpc_id

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

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ingress-alb-sg"
  })
}

# App VPC: Web Tier Security Group
# Allows HTTP/HTTPS strictly from Ingress VPC (load balancer)
resource "aws_security_group" "app_web_sg" {
  name        = "${var.project_name}-app-web-sg"
  description = "Security group for web tier in App VPC"
  vpc_id      = module.spoke_vpcs["app"].vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/24"]
    description = "Allow HTTP from Ingress VPC"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/24"]
    description = "Allow HTTPS from Ingress VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-web-sg"
  })
}

# App VPC: Database Tier Security Group
# Allows MySQL strictly from App VPC (web tier)
resource "aws_security_group" "app_db_sg" {
  name        = "${var.project_name}-app-db-sg"
  description = "Security group for database tier in App VPC"
  vpc_id      = module.spoke_vpcs["app"].vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.10.8.0/21"]
    description = "Allow MySQL from App VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-db-sg"
  })
}

# DMZ VPC: SSM/Control Plane Security Group
# Allows HTTPS for SSM Session Manager and control plane communications
resource "aws_security_group" "dmz_ssm_sg" {
  name        = "${var.project_name}-dmz-ssm-sg"
  description = "Security group for SSM endpoints and control plane in DMZ VPC"
  vpc_id      = module.spoke_vpcs["dmz"].vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.2.0/24"]
    description = "Allow HTTPS for SSM Session Manager and control plane"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dmz-ssm-sg"
  })
}

# Modern DMZ: AWS Systems Manager VPC Endpoints (replaces Bastion Host)
# These endpoints enable secure Session Manager access without requiring a Bastion instance

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.spoke_vpcs["dmz"].vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.spoke_vpcs["dmz"].private_subnets
  security_group_ids  = [aws_security_group.dmz_ssm_sg.id]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dmz-ssm-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.spoke_vpcs["dmz"].vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.spoke_vpcs["dmz"].private_subnets
  security_group_ids  = [aws_security_group.dmz_ssm_sg.id]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dmz-ssmmessages-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.spoke_vpcs["dmz"].vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.spoke_vpcs["dmz"].private_subnets
  security_group_ids  = [aws_security_group.dmz_ssm_sg.id]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-dmz-ec2messages-endpoint"
  })
}

# Outputs for validation and downstream resource attachment

output "security_group_ids" {
  description = "Security group IDs keyed by purpose"
  value = {
    ingress_alb = aws_security_group.ingress_alb_sg.id
    app_web     = aws_security_group.app_web_sg.id
    app_db      = aws_security_group.app_db_sg.id
    dmz_ssm     = aws_security_group.dmz_ssm_sg.id
  }
}

output "ssm_endpoint_ids" {
  description = "SSM VPC endpoint IDs for DMZ"
  value = {
    ssm         = aws_vpc_endpoint.ssm.id
    ssmmessages = aws_vpc_endpoint.ssmmessages.id
    ec2messages = aws_vpc_endpoint.ec2messages.id
  }
}

output "ssm_endpoint_dns_names" {
  description = "DNS names of SSM endpoints for reference"
  value = {
    ssm         = aws_vpc_endpoint.ssm.dns_entry[0].dns_name
    ssmmessages = aws_vpc_endpoint.ssmmessages.dns_entry[0].dns_name
    ec2messages = aws_vpc_endpoint.ec2messages.dns_entry[0].dns_name
  }
}
