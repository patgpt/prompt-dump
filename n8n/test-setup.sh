#!/bin/bash

# Test script for AI Memory System
# Run this after setup to verify everything is working

echo "🧪 Testing AI Memory System..."

# Test database connections
echo "Testing PostgreSQL connection..."
if docker-compose exec -T postgres psql -U memory_user -d ai_memory -c "SELECT 1;" > /dev/null 2>&1; then
    echo "✅ PostgreSQL connection successful"
else
    echo "❌ PostgreSQL connection failed"
    exit 1
fi

echo "Testing Memgraph connection..."
if curl -f http://localhost:3000/ > /dev/null 2>&1; then
    echo "✅ Memgraph HTTP interface accessible"
else
    echo "❌ Memgraph HTTP interface not accessible"
    echo "   Check if Memgraph container is running: docker ps | grep memgraph"
    exit 1
fi

echo "Testing n8n health..."
if curl -f http://localhost:5678/rest/ping > /dev/null 2>&1; then
    echo "✅ n8n is responding"
else
    echo "⚠️ n8n health check failed - this might be normal if still starting"
fi

# Test memory insertion
echo "Testing memory insertion..."
TEST_MESSAGE="Test message for AI memory system $(date)"

if curl -f -X POST http://localhost:5678/webhook/memory \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"$TEST_MESSAGE\", \"user_id\": \"test_user\", \"session_id\": \"test_session\"}" > /dev/null 2>&1; then
    echo "✅ Memory insertion test passed"
else
    echo "⚠️ Memory insertion test failed - this might be normal if workflow not imported yet"
fi

echo ""
echo "🎯 Quick verification queries:"
echo ""
echo "PostgreSQL - Check recent memories:"
echo "  docker-compose exec postgres psql -U memory_user -d ai_memory -c 'SELECT message, category FROM memory_chunks ORDER BY timestamp DESC LIMIT 3;'"
echo ""
echo "Memgraph - Check graph nodes:"
echo "  curl 'http://localhost:3000/query?query=MATCH%20(n)-%3E(m)%20RETURN%20count(*)'"
echo ""
echo "n8n - Import workflow and test webhook:"
echo "  1. Go to http://localhost:5678"
echo "  2. Import: ai-memory-workflow.json"
echo "  3. Set GEMINI_API_KEY in environment variables"
echo "  4. Test webhook: POST http://localhost:5678/webhook/memory"
