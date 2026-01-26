#!/bin/bash
set -e

# SSL Certificate Setup Script
# Uses Let's Encrypt to obtain certificates for all subdomains

EMAIL="${1:-admin@xyler.io}"

echo "=== SSL Certificate Setup ==="
echo "Using email: $EMAIL"

# Obtain certificates for all domains
echo "Obtaining SSL certificates..."

sudo certbot --nginx -d aura.xyler.io -d api.aura.xyler.io -d admin.aura.xyler.io \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    --redirect

# Set up auto-renewal
echo "Setting up auto-renewal..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Test renewal
echo "Testing certificate renewal..."
sudo certbot renew --dry-run

echo ""
echo "=== SSL Setup Complete ==="
echo "Certificates obtained for:"
echo "  - aura.xyler.io"
echo "  - api.aura.xyler.io"
echo "  - admin.aura.xyler.io"
echo ""
echo "Auto-renewal is configured and will run twice daily"
echo ""
echo "Your sites are now accessible at:"
echo "  - https://aura.xyler.io"
echo "  - https://api.aura.xyler.io"
echo "  - https://admin.aura.xyler.io"
