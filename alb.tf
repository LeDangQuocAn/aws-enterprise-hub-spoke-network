resource "aws_lb" "ingress_alb" {
  name               = "educloud-ingress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ingress_alb_sg.id]
  subnets            = module.spoke_vpcs["ingress"].public_subnets

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ingress-alb"
  })
}

resource "aws_lb_target_group" "app_targets" {
  name        = "educloud-app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.spoke_vpcs["app"].vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(local.common_tags, {
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
