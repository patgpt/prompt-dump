# AI Memory System with Vector Storage - n8n Workflow

This n8n workflow implements a persistent, accurate memory system for AI applications using PostgreSQL with vector extensions, Memgraph for relationship tracking, and Google's Gemini AI as the default language model.

## Features

- **Text Classification**: Automatically categorizes incoming messages using Gemini AI
- **Vector Embeddings**: Uses Gemini's embedding model for semantic search
- **Persistent Storage**: Stores memories in PostgreSQL with pgvector extension
- **Graph Relationships**: Tracks relationships in Memgraph
- **Semantic Search**: Retrieves relevant memories using vector similarity
- **Reranking**: Synthesizes and ranks retrieved memories for context using Gemini AI
- **Multi-session Support**: Supports multiple users and sessions

## Prerequisites

### Database Setup

1. **PostgreSQL with pgvector extension**:

   ```sql
   -- Install pgvector extension
   CREATE EXTENSION vector;

   -- Create memory chunks table
   CREATE TABLE memory_chunks (
     id TEXT PRIMARY KEY,
     user_id TEXT NOT NULL,
     session_id TEXT NOT NULL,
     message TEXT NOT NULL,
     category TEXT NOT NULL,
     embedding vector(1536), -- OpenAI embedding dimension
     timestamp TIMESTAMP DEFAULT NOW()
   );

   -- Create index for vector similarity search
   CREATE INDEX ON memory_chunks USING ivfflat (embedding vector_cosine_ops);
   ```

2. **Memgraph Database**:

   ```sql
   -- Create nodes table for relationships
   CREATE TABLE memgraph_nodes (
     id TEXT PRIMARY KEY,
     type TEXT NOT NULL,
     properties JSONB
   );

   -- Create relationships table
   CREATE TABLE memgraph_relationships (
     id TEXT PRIMARY KEY,
     from_node TEXT,
     to_node TEXT,
     type TEXT,
     properties JSONB
   );
   ```

### n8n Setup

1. Import the workflow JSON file into n8n
2. Configure your Gemini API key in the environment variables
3. Update database connection strings in PostgreSQL nodes
4. Test the webhook endpoint

## API Usage

### Send Message for Memory Storage

**POST** `/memory`

```json
{
  "message": "Your message here that you want to remember",
  "user_id": "user123",
  "session_id": "session456"
}
```

### Response Format

```json
{
  "user_id": "user123",
  "session_id": "session456",
  "message": "Your message here",
  "category": "conversation",
  "relevant_memories": [
    {
      "id": "msg_123",
      "message": "Previous related message",
      "category": "question",
      "similarity": 0.85
    }
  ],
  "synthesized_context": "Combined context from relevant memories...",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## Workflow Nodes Explained

1. **Webhook Input**: Receives chat messages via HTTP POST
2. **Extract Input Data**: Parses and structures the incoming data
3. **Classify Message**: Uses GPT to categorize the message type
4. **Generate Embedding**: Creates vector representation using OpenAI
5. **Store in PostgreSQL**: Saves the message and vector to database
6. **Retrieve Similar Memories**: Finds semantically similar past messages
7. **Store in Memgraph**: Records the message in the graph database
8. **Rerank and Synthesize**: Uses AI to rank and combine relevant memories
9. **Prepare Response**: Formats the final response with context

## Configuration Options

### Vector Search Parameters

- **Similarity Threshold**: Adjust the cosine similarity threshold in the query
- **Result Limit**: Control how many similar memories to retrieve
- **Embedding Model**: Currently using `text-embedding-ada-002` (1536 dimensions)

### Classification Categories

Current categories:

- conversation
- question
- instruction
- reflection
- planning
- creative
- technical
- personal

### Memory Types

- **Episodic Memory**: Specific conversations and interactions
- **Semantic Memory**: Factual information and knowledge
- **Procedural Memory**: Instructions and processes
- **Reflective Memory**: Insights and learnings

## Use Cases

1. **Chatbot Memory**: Maintain conversation context across sessions
2. **Personal AI Assistant**: Remember user preferences and history
3. **Knowledge Base**: Store and retrieve learned information
4. **Creative Writing**: Track story elements and character development
5. **Learning Companion**: Remember study progress and concepts
6. **Project Management**: Track decisions, tasks, and progress

## Performance Considerations

- **Vector Indexing**: Use IVFFlat index for large datasets
- **Batch Processing**: Consider batching similar operations
- **Caching**: Cache frequent queries and classifications
- **Cleanup Jobs**: Implement periodic cleanup of old memories

## Monitoring and Maintenance

- Monitor vector search performance
- Track memory retrieval accuracy
- Implement memory consolidation strategies
- Regular backup of both PostgreSQL and Memgraph data

## Extending the Workflow

To add new features:

1. **Additional Classifications**: Add new categories in the classification node
2. **Multi-modal Support**: Add image/audio processing nodes
3. **Advanced Reranking**: Implement more sophisticated ranking algorithms
4. **Memory Types**: Add different memory storage strategies
5. **External Integrations**: Connect with external knowledge sources

## Troubleshooting

### Common Issues

1. **Vector Extension Not Found**: Ensure pgvector is properly installed
2. **OpenAI API Errors**: Check API key and rate limits
3. **Database Connection**: Verify connection strings and permissions
4. **Memory Not Retrieved**: Check vector similarity thresholds
5. **Classification Errors**: Review category definitions and examples

### Debug Mode

Enable debug logging in n8n to see:

- API request/response details
- Database query execution
- Vector similarity calculations
- Classification results

## Security Considerations

- Implement proper authentication on webhook endpoints
- Encrypt sensitive data before storage
- Regular security updates for all components
- Monitor for unauthorized access attempts
- Implement rate limiting to prevent abuse

This workflow provides a solid foundation for building AI systems with persistent, context-aware memory capabilities.
