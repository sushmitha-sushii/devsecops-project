provider "aws" {
  region = "ap-south-1"
}

variable "key_name" {
  default = "devsecops-key-new"
}

variable "ami_id" {
  default = "ami-0f5ee92e2d63afc18"
}

variable "instance_type" {
  default = "t2.micro"
}

resource "aws_security_group" "web_sg" {
  name = "web-sg-new"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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

output "blue_ip" {
  value = aws_instance.blue.public_ip
}

output "green_ip" {
  value = aws_instance.green.public_ip
}
