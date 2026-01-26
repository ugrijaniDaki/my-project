#!/bin/bash
set -e

# Nginx Configuration Script for Aura Project
# Creates nginx configs for all subdomains

DOMAIN="aura.xyler.io"

echo "=== Nginx Configuration Setup ==="

# Create nginx config for main domain (aura.xyler.io) - Flutter mobile app
sudo tee /etc/nginx/sites-available/aura.xyler.io > /dev/null <<'EOF'
server {
    listen 80;
    server_name aura.xyler.io;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
}
EOF

# Create nginx config for API (api.aura.xyler.io)
sudo tee /etc/nginx/sites-available/api.aura.xyler.io > /dev/null <<'EOF'
server {
    listen 80;
    server_name api.aura.xyler.io;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
        client_max_body_size 50M;
    }
}
EOF

# Create nginx config for Admin (admin.aura.xyler.io)
sudo tee /etc/nginx/sites-available/admin.aura.xyler.io > /dev/null <<'EOF'
server {
    listen 80;
    server_name admin.aura.xyler.io;

    location / {
        proxy_pass http://127.0.0.1:8080/admin/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable sites
sudo ln -sf /etc/nginx/sites-available/aura.xyler.io /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/api.aura.xyler.io /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/admin.aura.xyler.io /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t

# Reload nginx
echo "Reloading nginx..."
sudo systemctl reload nginx

echo ""
echo "=== Nginx Configuration Complete ==="
echo "Sites enabled:"
echo "  - aura.xyler.io -> http://127.0.0.1:8080"
echo "  - api.aura.xyler.io -> http://127.0.0.1:8080"
echo "  - admin.aura.xyler.io -> http://127.0.0.1:8080/admin/"
echo ""
echo "Now run ./setup-ssl.sh to configure SSL certificates"
