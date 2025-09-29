#!/bin/bash

# AI Memory System Setup Script - Local Development

set -e

echo "🤖 Setting up AI Memory System (Local Development)..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 .env file already exists with development defaults"
fi

# Check if Gemini API key is set
if ! grep -q "GEMINI_API_KEY=" .env; then
    echo ""
    echo "⚠️  WARNING: Gemini API key not configured!"
    echo ""
    echo "Please edit the .env file and set your Gemini API key:"
    echo "GEMINI_API_KEY=your_gemini_api_key_here"
    echo ""
    echo "You can get an API key from: https://aistudio.google.com/app/apikey"
    echo ""
    read -p "Press Enter to continue (or Ctrl+C to abort)..."
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs
mkdir -p backups

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose down 2>/dev/null || true

# Remove n8n data volume to prevent encryption key conflicts
echo "🗑️ Cleaning n8n settings to prevent encryption key conflicts..."
docker volume rm n8n_n8n_data 2>/dev/null || true

# Also check if there are any existing n8n containers with old settings
echo "🔍 Checking for existing n8n containers..."
if docker ps -a --filter "name=ai-memory-n8n" | grep -q ai-memory-n8n; then
    echo "📦 Found existing n8n container, removing..."
    docker rm -f ai-memory-n8n 2>/dev/null || true
fi

# Start the services
echo "🚀 Starting AI Memory System services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to start..."
sleep 15

# Check service health
echo "🔍 Checking service health..."

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U memory_user -d ai_memory > /dev/null 2>&1; then
    echo "✅ PostgreSQL is ready"
else
    echo "❌ PostgreSQL failed to start. Check logs with: docker-compose logs postgres"
    exit 1
fi

# Check Memgraph
if curl -f http://localhost:3000/ > /dev/null 2>&1; then
    echo "✅ Memgraph is ready"
else
    echo "❌ Memgraph failed to start. Check logs with: docker-compose logs memgraph"
    exit 1
fi

# Check n8n
sleep 10
if curl -f http://localhost:5678/rest/ping > /dev/null 2>&1; then
    echo "✅ n8n is ready"
else
    echo "⚠️ n8n not ready yet, but continuing... Check logs with: docker-compose logs n8n"
fi

echo ""
echo "🎉 AI Memory System setup complete!"
echo ""
echo "🔗 Services available at:"
echo "• PostgreSQL: localhost:5432 (database: ai_memory, user: memory_user)"
echo "• Memgraph:   localhost:3000 (HTTP), localhost:7687 (Bolt)"
echo "• n8n:        localhost:5678"
echo "• Qdrant:     localhost:6333"
echo ""
echo "📝 Next steps:"
echo "1. Edit .env file and set your GEMINI_API_KEY"
echo "2. Import the workflow: ai-memory-workflow.json into n8n"
echo "3. Test the webhook endpoint: POST http://localhost:5678/webhook/memory"
echo ""
echo "🛠️  Useful commands:"
echo "• View logs: docker-compose logs -f [service_name]"
echo "• Stop all:  docker-compose down"
echo "• Restart:   docker-compose restart"
echo ""
echo "📖 For more details, see README-docker.md"
echo ""
echo "🔧 Troubleshooting:"
echo "• If you get encryption key errors, run: ./clean-setup.sh"
echo "• This will completely reset n8n data and start fresh"
echo "• If Memgraph fails to start, check: docker-compose logs memgraph"
