#!/bin/bash
set -e

# Aura Project Deployment Script
# This script fetches the latest code from GitHub and rebuilds Docker containers

REPO_URL="https://github.com/davids1z/my-project.git"
APP_DIR="/opt/aura"
BACKUP_DIR="/opt/aura-backups"

echo "=== Aura Deployment Script ==="
echo "Started at: $(date)"

# Create directories if they don't exist
sudo mkdir -p $APP_DIR $BACKUP_DIR

# Check if this is first run or update
if [ -d "$APP_DIR/.git" ]; then
    echo "Updating existing installation..."
    cd $APP_DIR

    # Backup current state
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    echo "Creating backup: $BACKUP_NAME"
    sudo tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" --exclude='.git' --exclude='postgres_data' .

    # Pull latest changes
    sudo git fetch origin
    sudo git reset --hard origin/main
else
    echo "Fresh installation..."
    cd /opt
    sudo rm -rf aura
    sudo git clone $REPO_URL $APP_DIR
    cd $APP_DIR
fi

# Load environment variables if .env exists
if [ -f "$APP_DIR/.env" ]; then
    echo "Loading environment variables..."
    export $(grep -v '^#' $APP_DIR/.env | xargs)
fi

# Stop existing containers
echo "Stopping existing containers..."
sudo docker compose down --remove-orphans 2>/dev/null || true

# Build and start containers
echo "Building and starting containers..."
sudo docker compose build --no-cache
sudo docker compose up -d

# Wait for services to be healthy
echo "Waiting for services to start..."
sleep 10

# Check container status
echo "Container status:"
sudo docker compose ps

# Show logs
echo "Recent logs:"
sudo docker compose logs --tail=20

echo ""
echo "=== Deployment completed at $(date) ==="
echo "Backend running on: http://127.0.0.1:8080"
echo "PostgreSQL running on: 127.0.0.1:5432"
