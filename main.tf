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

  # FIXED: Uses templatefile to cleanly parse the bash script without syntax collisions
  user_data = templatefile("${path.module}/userdata.sh", {
    html_content = file("${path.module}/index.html")
  })

  tags = {
    Name = "My-Automation-Test-Ohio"
  }
}

# This will fetch and print the dynamic public IP assigned by AWS
output "server_public_ip" {
  value = "http://${aws_instance.my_server.public_ip}"
}
