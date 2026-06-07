provider "aws" {
  region = "us-east-2" # CHOSEN REGION: Ohio
}

# 1. Create a firewall group to allow public web access
resource "aws_security_group" "web_sg" {
  name        = "allow-web-traffic-ohio"
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

# 2. Launch a single free-tier EC2 Linux server
resource "aws_instance" "my_server" {
  ami                         = "ami-0b9064170e32bde34" # Standard Ubuntu 22.04 AMI inside us-east-2 (Ohio)
  instance_type               = "t2.micro"             # 100% Free-Tier eligible
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  
  # Forces the server to swap out cleanly when your text changes
  user_data_replace_on_change = true 

  # This Linux script runs instantly when the server boots up
  user_data = <<-EOF
              #!/bin/bash
              echo "${file("index.html")}" > index.html
              python3 -m http.server 80 &
              EOF

  tags = {
    Name = "My-Automation-Test-Ohio"
  }
}

# 3. Print the final IP address into the GitHub Action logs
output "server_public_ip" {
  value = "http://${aws_instance.my_server.public_ip}"
}
