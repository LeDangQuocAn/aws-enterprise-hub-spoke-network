data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_iam_role" "app_ec2_role" {
  name = "${var.project_name}-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_ec2_profile" {
  name = "${var.project_name}-app-ec2-profile"
  role = aws_iam_role.app_ec2_role.name

  tags = var.common_tags
}

resource "aws_instance" "app_servers" {
  count = length(var.private_subnet_ids["app"])

  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_ids["app"][count.index]
  vpc_security_group_ids      = [var.app_web_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.app_ec2_profile.name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "<h1>Hello from EduCloud App Tier</h1><p>Availability Zone: $AZ</p>" > /var/www/html/index.html
  EOF

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-server-${count.index + 1}"
  })
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  count = length(var.private_subnet_ids["app"])

  target_group_arn  = aws_lb_target_group.app_targets.arn
  target_id         = aws_instance.app_servers[count.index].private_ip
  port              = 80
  availability_zone = "all"
}
