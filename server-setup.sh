#!/bin/bash
set -e

# Server Setup Script for Aura Project
# Run this script on a fresh Ubuntu/Debian server

echo "=== Aura Server Setup Script ==="
echo "Started at: $(date)"

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "Installing nginx..."
sudo apt install -y nginx

echo "Installing Docker..."
# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install Docker dependencies
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Certbot for Let's Encrypt
echo "Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Create application directory
echo "Creating application directories..."
sudo mkdir -p /opt/aura
sudo mkdir -p /opt/aura-backups
sudo chown -R $USER:$USER /opt/aura /opt/aura-backups

# Enable and start nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo ""
echo "=== Base Setup Complete ==="
echo "Docker version: $(docker --version)"
echo "Nginx version: $(nginx -v 2>&1)"
echo ""
echo "Next steps:"
echo "1. Run the Cloudflare DNS setup"
echo "2. Run: ./deploy.sh to deploy the application"
echo "3. Run: ./setup-ssl.sh to configure SSL certificates"
echo "4. Run: ./setup-nginx.sh to configure nginx"
