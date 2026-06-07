#!/bin/bash
# Update packages and make sure python3 is ready
apt-get update -y
apt-get install -y python3

# Navigate to the home directory
cd /home/ubuntu

# Write the actual contents of your local index.html file into the EC2 instance
cat << 'EOF' > index.html
${html_content}
EOF

# Fix permissions so everything can read it
chown ubuntu:ubuntu index.html
chmod 644 index.html

# Run the server on port 80 as root and bind to all incoming network interfaces
nohup python3 -m http.server 80 --bind 0.0.0.0 > /home/ubuntu/server.log 2>&1 &
