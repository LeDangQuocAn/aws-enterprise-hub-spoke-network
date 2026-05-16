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

resource "aws_instance" "app_servers" {
  count = length(local.vpc_azs)

  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = module.spoke_vpcs["app"].private_subnets[count.index]
  vpc_security_group_ids      = [aws_security_group.app_web_sg.id]
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

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-app-server-${count.index + 1}"
  })
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  count = length(local.vpc_azs)

  target_group_arn  = aws_lb_target_group.app_targets.arn
  target_id         = aws_instance.app_servers[count.index].private_ip
  port              = 80
  availability_zone = "all"
}
