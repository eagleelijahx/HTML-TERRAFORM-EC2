provider "aws" {
  region = "us-east-2" # Ohio Data Center
}

# 1. Generates a random string to prevent duplicate firewall errors
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# 2. Creates the firewall network rules
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

# 3. Launches the free-tier EC2 Linux server
resource "aws_instance" "my_server" {
  ami                         = "ami-0b9064170e32bde34" # Ubuntu 22.04 LTS (Ohio)
  instance_type               = "t3.micro"              # Free-Tier eligible
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  
  # FORCE AWS TO ASSIGN A PUBLIC IP
  associate_public_ip_address = true 
  
  user_data_replace_on_change = true 

  user_data = <<-EOF
#!/bin/bash
cd /home/ubuntu
cat << 'INNER_EOF' > index.html
${file("index.html")}
INNER_EOF
nohup python3 -m http.server 80 > server.log 2>&1 &
EOF

  tags = {
    Name = "My-Automation-Test-Ohio"
  }
}

output "server_public_ip" {
  value = "http://${aws_instance.my_server.public_ip}"
}
