locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_lb" "ingress_alb" {
  name               = "educloud-ingress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.ingress_alb_sg_id]
  subnets            = var.public_subnet_ids["ingress"]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-ingress-alb"
  })
}

resource "aws_lb_target_group" "app_targets" {
  name        = "educloud-app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_ids["ingress"]

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ingress_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_targets.arn
  }
}

resource "aws_wafv2_web_acl_association" "ingress_alb" {
  resource_arn = aws_lb.ingress_alb.arn
  web_acl_arn  = var.web_acl_arn
}
