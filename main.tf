terraform {
  required_version = ">= 1.0.0"
  
  backend "s3" {
    bucket         = "my-terraform-state-bucket-illia-123" # Make sure this matches your actual S3 bucket!
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2" 
}

# Automatically use your account's Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Simple firewall rule allowing HTTP traffic
resource "aws_security_group" "web_sg" {
  name        = "allow-web-traffic-ohio"
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

# Launching the EC2 server
resource "aws_instance" "my_server" {
  ami                         = "ami-0b9064170e32bde34" # Ubuntu 22.04 LTS (Ohio)
  instance_type               = "t3.micro"              
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true 
  
  # CRITICAL: This forces Terraform to destroy the old instance and build a new one whenever user_data changes
  user_data_replace_on_change = true 

  # Simplified inline user data script to install Apache and host a simple page
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Hello World from my automated EC2 instance!</h1>" > /var/var/www/html/index.html
              EOF

  tags = {
    Name = "My-Automation-Test-Ohio"
  }
}

output "server_public_ip" {
  value = "http://${aws_instance.my_server.public_ip}"
}
