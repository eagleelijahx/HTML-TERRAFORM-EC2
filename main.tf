provider "aws" {
  region = "us-east-2" # Ohio Data Center
}

# 1. This generates a random string of 4 letters automatically
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# 2. We attach that random string directly to the firewall name
resource "aws_security_group" "web_sg" {
  name        = "allow-web-traffic-ohio-${random_string.suffix.result}" 
  description = "Allow HTTP inbound traffic"

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

# 3. Launch a single free-tier EC2 Linux server
resource "aws_instance" "my_server" {
  ami                         = "ami-0b9064170e32bde34" # Standard Ubuntu 22.04 AMI inside us-east-2 (Ohio)
  instance_type               = "t3.micro"             # 100% Free-Tier eligible
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  
  user_data_replace_on_change = true 

  user_data = <<-EOF
              #!/bin/bash
              echo "${file("index.html")}" > index.html
              python3 -m http.server 80 &
              EOF

  tags = {
    Name = "My-Automation-Test-Ohio"
  }
}

output "server_public_ip" {
  value = "http://${aws_instance.my_server.public_ip}"
}

