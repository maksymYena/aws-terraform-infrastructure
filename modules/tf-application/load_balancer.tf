resource "aws_security_group" "alb_sg" {
  name        = "image-recognition-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_inbound" {
  #checkov:skip=CKV_AWS_260:Public HTTP access is required for the training demo application.

  security_group_id = aws_security_group.alb_sg.id

  description = "Allow HTTP traffic to ALB"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_outbound" {
  security_group_id = aws_security_group.alb_sg.id

  description = "Allow outbound traffic from ALB"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# tfsec:ignore:aws-elb-alb-not-public
# Public ALB is required to expose the demo application API.
resource "aws_lb" "application_lb" {
  #checkov:skip=CKV_AWS_91:ALB access logging is outside the scope of this training environment.
  #checkov:skip=CKV_AWS_150:Deletion protection is disabled to support terraform destroy after the demo.
  #checkov:skip=CKV2_AWS_20:HTTPS and ACM are outside the scope of this training environment.
  #checkov:skip=CKV2_AWS_28:AWS WAF is outside the scope of this training environment.

  name               = "image-recognition-alb"
  internal           = false #tfsec:ignore:aws-elb-alb-not-public
  load_balancer_type = "application"

  subnets = var.subnet_ids

  security_groups = [aws_security_group.alb_sg.id]

  drop_invalid_header_fields = true
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "application_target_group" {
  #checkov:skip=CKV_AWS_378:HTTP between ALB and ECS is acceptable for this training environment.

  name        = "image-recognition-tg"
  port        = var.application_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

# tfsec:ignore:aws-elb-http-not-used
# HTTPS requires an ACM certificate/domain and is outside the scope of this training environment.
resource "aws_lb_listener" "application_listener" {
  #checkov:skip=CKV_AWS_2:HTTPS and ACM certificate configuration are outside the scope of this training environment.
  #checkov:skip=CKV_AWS_103:TLS policy is not applicable because the demo listener intentionally uses HTTP.

  load_balancer_arn = aws_lb.application_lb.arn

  port     = var.application_port
  protocol = "HTTP" #tfsec:ignore:aws-elb-http-not-used

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application_target_group.arn
  }
}