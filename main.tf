terraform {
  required_version = ">= 1.0.0"
  
  backend "s3" {
    bucket         = "my-terraform-state-bucket-illia-123" # <--- Swap this to your real bucket name!
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2" # Ohio Data Center
}

# Automatically look up your account's Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Generates a random string to prevent duplicate firewall errors
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Creates the firewall network rules linked to your Default VPC
resource "aws_security_group" "web_sg" {
  name        = "allow-web-traffic-ohio-${random_string.suffix.result}" 
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

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

# Launches the free-tier EC2 Linux server
resource "aws_instance" "my_server" {
  ami                         = "ami-0b9064170e32bde34" # Ubuntu 22.04 LTS (Ohio)
  instance_type               = "t3.micro"              # Free-Tier eligible
  
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true 
  
  user_data_replace_on_change = true 

  user_data = <<-EOF
#!/bin/bash
cd /home/ubuntu
cat << 'INNER_EOF' > index.html
${file("index.html")}
INNER_EOF
chown ubuntu:ubuntu index.html
(while true; do python3 -m http.server 80; sleep 1; done) > /home/ubuntu/server.log 2>&1 &
EOF

  tags = {
    Name = "My-Automation-Test-Ohio"
  }
}

# NEW: Allocates a permanent static Elastic IP and pins it to your EC2 instance
resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_server.id
  domain   = "vpc"

  tags = {
    Name = "My-Permanent-Web-IP"
  }
}

# UPDATED OUTPUT: This output link will now stay exactly the same every time you push code
output "server_public_ip" {
  value = "http://${aws_eip.my_static_ip.public_ip}"
}
