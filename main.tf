provider "aws" {
  region = "ap-south-1"
}

# ---------------- VARIABLES ----------------

variable "key_name" {
  default = "devsecops-key-new"
}

variable "ami_id" {
  default = "ami-0f5ee92e2d63afc18"
}

variable "instance_type" {
  default = "t2.micro"
}

# ---------------- DATA ----------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {}

# ---------------- SECURITY GROUP ----------------

resource "aws_security_group" "web_sg" {
  name = "web-sg-new"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# ---------------- EC2 INSTANCES ----------------

resource "aws_instance" "blue" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Blue-Server"
  }
}

resource "aws_instance" "green" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Green-Server"
  }
}

# ---------------- LOAD BALANCER ----------------

resource "aws_lb" "alb" {
  name               = "devsecops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = data.aws_subnets.default.ids
}

# ---------------- TARGET GROUPS ----------------
resource "aws_lb_target_group" "blue" {
  name     = "blue-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_target_group" "green" {
  name     = "green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

# ---------------- ATTACH INSTANCES ----------------

resource "aws_lb_target_group_attachment" "blue_attach" {
  target_group_arn = aws_lb_target_group.blue.arn
  target_id        = aws_instance.blue.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "green_attach" {
  target_group_arn = aws_lb_target_group.green.arn
  target_id        = aws_instance.green.id
  port             = 80
}

# ---------------- LISTENER ----------------

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

# ---------------- OUTPUTS ----------------

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "blue_public_ip" {
  value = aws_instance.blue.public_ip
}

output "green_public_ip" {
  value = aws_instance.green.public_ip
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  value = aws_lb_target_group.green.arn
}

output "listener_arn" {
  value = aws_lb_listener.listener.arn
}
