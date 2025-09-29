# AI Memory System - Docker Setup

This guide explains how to set up the AI Memory System using Docker Compose for local development and testing.

## Architecture

The system consists of several containerized services:

- **PostgreSQL + pgvector**: Vector database for semantic search and memory storage
- **Memgraph**: Graph database for relationship tracking between memories
- **n8n**: Workflow automation platform for orchestrating the memory system
- **Qdrant**: Alternative vector database (optional)

## Quick Start

### 1. Prerequisites

- Docker and Docker Compose
- Gemini API key (Google AI Studio)
- Git (for cloning or downloading files)

### 2. Setup

```bash
# Clone or download the project files
git clone <repository-url>
cd ai-memory-system

# Run the setup script
./setup.sh
```

The setup script will:

- Create a `.env` file from `.env.example`
- Generate secure encryption keys
- Start all services
- Verify service health

### 3. Configure Environment

Edit the `.env` file with your actual values:

```bash
# Required
POSTGRES_PASSWORD=your_secure_password
N8N_DB_PASSWORD=your_secure_password
GEMINI_API_KEY=your_gemini_api_key

# Optional
N8N_ENCRYPTION_KEY=your_32_char_key
WEBHOOK_URL=http://localhost:5678
OPENAI_API_KEY=optional_openai_api_key
```

### 4. Start Services

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Services

### PostgreSQL (pgvector)

- **Port**: 5432
- **Database**: `ai_memory`
- **User**: `n8n_user`
- **Features**: Vector storage, full-text search, JSON support

### Memgraph

- **HTTP Port**: 3000 (Memgraph Lab interface)
- **Bolt Port**: 7687 (Cypher queries)
- **Features**: Graph relationships, pattern matching, real-time queries

### n8n

- **Port**: 5678
- **Features**: Workflow automation, API integrations, webhook handling

### Qdrant (Optional)

- **REST API**: 6333
- **gRPC**: 6334
- **Features**: High-performance vector search, filtering, multi-vector support

## Database Schema

### PostgreSQL Tables

- `memory_chunks`: Core memory storage with vector embeddings
- `conversation_sessions`: Session management
- `memory_relationships`: Memory-to-memory relationships
- `memory_summaries`: Compressed memory summaries

### Memgraph Graph

- `MemoryNode`: Individual memory entries
- `User`: System users
- `Session`: Conversation sessions
- `Category`: Memory categorization
- `SummaryNode`: Memory summaries

## Usage Examples

### Store a Memory

```bash
curl -X POST http://localhost:5678/webhook/memory \
  -H "Content-Type: application/json" \
  -d '{
    "message": "This is an important piece of information to remember",
    "user_id": "user123",
    "session_id": "session456"
  }'
```

### Query Similar Memories

```sql
-- From PostgreSQL
SELECT message, 1 - (embedding <=> $1::vector) as similarity
FROM memory_chunks
WHERE user_id = 'user123'
ORDER BY embedding <=> $1::vector
LIMIT 5;
```

```cypher
-- From Memgraph
MATCH (m:MemoryNode)-[:FOLLOWS*1..3]->(related:MemoryNode)
WHERE m.content CONTAINS "important"
RETURN related.content, count(*) as relevance
ORDER BY relevance DESC
LIMIT 5;
```

## Workflow Integration

1. **Import Workflow**: Import `ai-memory-workflow.json` into n8n
2. **Configure Credentials**: Set GEMINI_API_KEY in environment variables
3. **Update Database Connections**: Modify PostgreSQL node connection strings
4. **Test Webhook**: Send test requests to verify functionality

## Development

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f postgres
docker-compose logs -f memgraph
docker-compose logs -f n8n
```

### Access Databases

```bash
# PostgreSQL
docker-compose exec postgres psql -U n8n_user -d ai_memory

# Memgraph (via HTTP)
curl http://localhost:3000/

# Memgraph (via Bolt - use a client like memgraph-py)
```

### Backup Data

```bash
# PostgreSQL
docker-compose exec postgres pg_dump -U n8n_user ai_memory > backup.sql

# Memgraph (export via HTTP API)
curl http://localhost:3000/dump
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**

   - Change ports in `docker-compose.yml`
   - Check if ports are already in use: `lsof -i :PORT`

2. **Service Won't Start**

   - Check logs: `docker-compose logs SERVICE_NAME`
   - Verify environment variables in `.env`
   - Ensure sufficient resources (memory, CPU)

3. **Database Connection Issues**

   - Wait for health checks to pass
   - Verify connection strings in n8n workflow
   - Check network connectivity between containers

4. **Memory Issues**
   - Increase Docker memory limits
   - Monitor resource usage: `docker stats`

### Reset Everything

```bash
# Stop services and remove volumes
docker-compose down -v

# Remove all containers and images (nuclear option)
docker-compose down --rmi all

# Start fresh
./setup.sh
```

## Production Deployment

For production use, consider:

1. **Security**

   - Use strong passwords
   - Enable TLS/SSL
   - Network isolation
   - Secrets management

2. **Performance**

   - Resource limits
   - Load balancing
   - Database optimization
   - Monitoring and alerting

3. **Backup Strategy**

   - Automated backups
   - Point-in-time recovery
   - Cross-region replication

4. **Scaling**
   - Horizontal scaling
   - Read replicas
   - Caching layers

## API Reference

### n8n Workflow Endpoints

- `POST /webhook/memory` - Store new memory
- `GET /webhook/memory/{id}` - Retrieve specific memory
- `POST /webhook/similar` - Find similar memories

### Health Checks

- PostgreSQL: `GET /health/postgres`
- Memgraph: `GET /health/memgraph`
- n8n: `GET /health/n8n`

## Contributing

1. Make changes to workflow or configuration
2. Test locally with Docker setup
3. Update documentation
4. Submit pull request

## License

[Add your license information here]
