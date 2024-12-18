# ターゲットグループの作成
resource "aws_lb_target_group" "this" {
  name = "${var.service_name}-${var.env}-alb-tg"

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path     = "/"
    interval = 300
    timeout  = 120
    port     = "traffic-port"
    protocol = "HTTP"
  }

  tags = {
    Name        = "${var.service_name}-${var.env}-alb-tg"
    Terraform   = "true"
    Environment = var.env
  }
}

# listener の作成
resource "aws_lb_listener" "http" {
  port              = "80"
  protocol          = "HTTP"
  load_balancer_arn = var.alb_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name        = "${var.service_name}-${var.env}-lb-http-listener"
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_security_group" "this" {
  name        = "${var.service_name}-${var.env}-sg"
  description = "${var.service_name}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.lb_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service_name}-${var.env}-sg"
    Terraform   = "true"
    Environment = var.env
  }
}