#!/bin/bash

# Clean Setup Script for AI Memory System
# This script completely removes n8n data and starts fresh

set -e

echo "🧽 Performing clean setup of AI Memory System..."
echo ""
echo "⚠️ WARNING: This will remove all existing n8n data!"
echo ""

read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Stop all services
echo "🛑 Stopping all services..."
docker-compose down 2>/dev/null || true

# Remove n8n volume completely
echo "🗑️ Removing n8n data volume..."
docker volume rm n8n_n8n_data 2>/dev/null || true

# Remove any orphaned containers
echo "🧹 Cleaning up orphaned containers..."
docker container prune -f 2>/dev/null || true

# Start services fresh
echo "🚀 Starting services with clean state..."
./setup.sh
