-- Initialize AI Memory Database

-- Create user if it doesn't exist (for safety)
DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'n8n_user') THEN
      CREATE USER n8n_user WITH PASSWORD 'n8n_password';
   END IF;
END
$$;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS uuid-ossp;

-- Grant permissions to n8n_user on ai_memory database
GRANT ALL PRIVILEGES ON DATABASE ai_memory TO n8n_user;

-- Switch to ai_memory database
\c ai_memory;

-- Create memory chunks table for vector storage
CREATE TABLE IF NOT EXISTS memory_chunks (
    id TEXT PRIMARY KEY DEFAULT ('msg_' || uuid_generate_v4()),
    user_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    message TEXT NOT NULL,
    category TEXT NOT NULL,
    embedding vector(1536), -- OpenAI ada-002 embedding dimension
    metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_memory_chunks_user_session
    ON memory_chunks(user_id, session_id);

CREATE INDEX IF NOT EXISTS idx_memory_chunks_timestamp
    ON memory_chunks(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_memory_chunks_category
    ON memory_chunks(category);

-- Create vector similarity index (IVFFlat for large datasets)
CREATE INDEX IF NOT EXISTS idx_memory_chunks_embedding
    ON memory_chunks USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_memory_chunks_updated_at
    BEFORE UPDATE ON memory_chunks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create table for conversation sessions
CREATE TABLE IF NOT EXISTS conversation_sessions (
    id TEXT PRIMARY KEY DEFAULT ('session_' || uuid_generate_v4()),
    user_id TEXT NOT NULL,
    title TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trigger for conversation_sessions
CREATE TRIGGER update_conversation_sessions_updated_at
    BEFORE UPDATE ON conversation_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create table for memory relationships (alternative to Memgraph)
CREATE TABLE IF NOT EXISTS memory_relationships (
    id TEXT PRIMARY KEY DEFAULT ('rel_' || uuid_generate_v4()),
    source_id TEXT NOT NULL REFERENCES memory_chunks(id) ON DELETE CASCADE,
    target_id TEXT NOT NULL REFERENCES memory_chunks(id) ON DELETE CASCADE,
    relationship_type TEXT NOT NULL,
    strength DECIMAL(3,2) DEFAULT 1.0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(source_id, target_id, relationship_type)
);

-- Create indexes for relationships
CREATE INDEX IF NOT EXISTS idx_memory_relationships_source
    ON memory_relationships(source_id);

CREATE INDEX IF NOT EXISTS idx_memory_relationships_target
    ON memory_relationships(target_id);

CREATE INDEX IF NOT EXISTS idx_memory_relationships_type
    ON memory_relationships(relationship_type);

-- Create table for memory summaries (compressed memories)
CREATE TABLE IF NOT EXISTS memory_summaries (
    id TEXT PRIMARY KEY DEFAULT ('summary_' || uuid_generate_v4()),
    user_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    summary_type TEXT NOT NULL, -- 'daily', 'weekly', 'topic', 'session'
    time_range_start TIMESTAMP WITH TIME ZONE,
    time_range_end TIMESTAMP WITH TIME ZONE,
    summary_text TEXT NOT NULL,
    key_points JSONB DEFAULT '[]',
    embedding vector(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for summaries
CREATE INDEX IF NOT EXISTS idx_memory_summaries_user_session
    ON memory_summaries(user_id, session_id);

CREATE INDEX IF NOT EXISTS idx_memory_summaries_type
    ON memory_summaries(summary_type);

CREATE INDEX IF NOT EXISTS idx_memory_summaries_time_range
    ON memory_summaries(time_range_start, time_range_end);

-- Insert some sample data for testing
INSERT INTO memory_chunks (user_id, session_id, message, category, embedding)
VALUES
    ('user_test', 'session_test', 'Hello, this is a test message for the AI memory system.', 'conversation', NULL),
    ('user_test', 'session_test', 'I need help with understanding vector databases.', 'question', NULL),
    ('user_test', 'session_test', 'Vector databases store data as high-dimensional vectors for similarity search.', 'technical', NULL)
ON CONFLICT (id) DO NOTHING;

-- Create view for recent memories
CREATE OR REPLACE VIEW recent_memories AS
SELECT
    mc.*,
    cs.title as session_title
FROM memory_chunks mc
LEFT JOIN conversation_sessions cs ON mc.session_id = cs.id
WHERE mc.timestamp >= NOW() - INTERVAL '7 days'
ORDER BY mc.timestamp DESC;

-- Create view for memory statistics
CREATE OR REPLACE VIEW memory_stats AS
SELECT
    user_id,
    session_id,
    category,
    COUNT(*) as message_count,
    MIN(timestamp) as first_message,
    MAX(timestamp) as last_message,
    EXTRACT(EPOCH FROM (MAX(timestamp) - MIN(timestamp))) / 60 as duration_minutes
FROM memory_chunks
GROUP BY user_id, session_id, category;

-- Grant permissions to n8n_user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO n8n_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO n8n_user;

COMMIT;
