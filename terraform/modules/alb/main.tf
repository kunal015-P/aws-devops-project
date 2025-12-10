variable "project" {}
variable "vpc_id" {}
variable "public_subnets" { type = list(string) }

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Allow HTTP"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
}

# Target Group (Fargate requires target_type = "ip")
resource "aws_lb_target_group" "tg" {
  name        = "${var.project}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"   # <<<<<< important for Fargate

  health_check {
    path     = "/actuator/health"
    interval = 30
    matcher  = "200"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Outputs
output "target_group_arn" { value = aws_lb_target_group.tg.arn }
output "alb_dns" { value = aws_lb.alb.dns_name }
