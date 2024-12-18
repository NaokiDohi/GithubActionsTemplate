# ALB
resource "aws_alb" "this" {
  name = "${var.service_name}-alb-${var.env}"

  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnets

  security_groups = [aws_security_group.this.id]
  tags = {
    Name        = "${var.service_name}-alb-${var.env}"
    Terraform   = "true"
    Environment = var.env
  }
}


# リスナーとは外部からALBが接続を待ち受けるポート/プロトコルをチェックするプロセスです。HTTPSのみのリクエストを待ち受けることにします。
resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.this.arn
  certificate_arn   = var.acm_arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = var.alb_target_group_arn
  }

  tags = {
    Name = "${var.service_name}-${var.env}-lb-https-listener"
  }
}

# リスナールールによってマッチしたURLのパスに応じたリクエストの振り分けをすることができます。
# resource "aws_alb_listener_rule" "https" {
#   listener_arn = aws_alb_listener.this.arn
#   priority     = 100
#   action {
#     type             = "forward"
#     target_group_arn = "${var.alb_target_group_arn}"
#   }

#   condition {
#     path_pattern {
#       values = ["/*"]
#     }
#   }
# }

resource "aws_lb_listener_rule" "http_to_https" {
  listener_arn = var.lb_listener_http_arn

  priority = 99

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = ["${var.domain_name}"]
    }
  }

  tags = {
    Name = "${var.service_name}-${var.env}-lb-http-to-https-listener"
  }
}


# SecurityGroup
resource "aws_security_group" "this" {
  name   = "${var.service_name}-alb-sg-${var.env}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service_name}-alb-sg-${var.env}"
    Terraform   = "true"
    Environment = var.env
  }
}