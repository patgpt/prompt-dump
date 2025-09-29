// Initialize AI Memory Graph Database

// Create constraints for data integrity
CREATE CONSTRAINT ON (n:MemoryNode) ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:User) ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:Session) ASSERT n.id IS UNIQUE;
CREATE CONSTRAINT ON (n:Category) ASSERT n.name IS UNIQUE;

// Create indexes for performance
CREATE INDEX ON :MemoryNode(timestamp);
CREATE INDEX ON :MemoryNode(category);
CREATE INDEX ON :User(id);
CREATE INDEX ON :Session(id);

// Create sample data structure
// Users
MERGE (user:user {id: 'user_test', name: 'Test User', created_at: datetime()});

// Sessions
MERGE (session:session {id: 'session_test', title: 'Test Session', created_at: datetime()});

// Categories
MERGE (conversation:category {name: 'conversation'});
MERGE (question:category {name: 'question'});
MERGE (technical:category {name: 'technical'});
MERGE (instruction:category {name: 'instruction'});
MERGE (reflection:category {name: 'reflection'});
MERGE (planning:category {name: 'planning'});
MERGE (creative:category {name: 'creative'});
MERGE (personal:category {name: 'personal'});

// Sample memory nodes
MERGE (memory1:MemoryNode {
    id: 'msg_001',
    content: 'Hello, this is a test message for the AI memory system.',
    category: 'conversation',
    timestamp: datetime(),
    importance: 0.7
});

MERGE (memory2:MemoryNode {
    id: 'msg_002',
    content: 'I need help with understanding vector databases.',
    category: 'question',
    timestamp: datetime(),
    importance: 0.8
});

MERGE (memory3:MemoryNode {
    id: 'msg_003',
    content: 'Vector databases store data as high-dimensional vectors for similarity search.',
    category: 'technical',
    timestamp: datetime(),
    importance: 0.9
});

// Create relationships
MATCH (m1:MemoryNode {id: 'msg_001'}), (m2:MemoryNode {id: 'msg_002'})
MERGE (m1)-[:FOLLOWS]->(m2);

MATCH (m2:MemoryNode {id: 'msg_002'}), (m3:MemoryNode {id: 'msg_003'})
MERGE (m2)-[:ANSWERED_BY]->(m3);

MATCH (m3:MemoryNode {id: 'msg_003'}), (tech:category {name: 'technical'})
MERGE (m3)-[:BELONGS_TO]->(tech);

// Link to user and session
MATCH (user:user {id: 'user_test'}), (session:session {id: 'session_test'})
MATCH (memory1:MemoryNode {id: 'msg_001'})
MATCH (memory2:MemoryNode {id: 'msg_002'})
MATCH (memory3:MemoryNode {id: 'msg_003'})
MERGE (memory1)-[:CREATED_BY]->(user);
MERGE (memory2)-[:CREATED_BY]->(user);
MERGE (memory3)-[:CREATED_BY]->(user);
MERGE (memory1)-[:PART_OF]->(session);
MERGE (memory2)-[:PART_OF]->(session);
MERGE (memory3)-[:PART_OF]->(session);

// Create summary nodes
MERGE (summary:SummaryNode {
    id: 'summary_session_test',
    type: 'session',
    content: 'Initial conversation about AI memory systems and vector databases',
    start_time: datetime(),
    end_time: datetime(),
    key_points: ['AI memory system introduction', 'Vector database explanation', 'Technical discussion']
});

// Link summary to memories
MATCH (summary:SummaryNode {id: 'summary_session_test'})
MATCH (m1:MemoryNode {id: 'msg_001'})
MATCH (m2:MemoryNode {id: 'msg_002'})
MATCH (m3:MemoryNode {id: 'msg_003'})
MERGE (summary)-[:SUMMARIZES]->(m1);
MERGE (summary)-[:SUMMARIZES]->(m2);
MERGE (summary)-[:SUMMARIZES]->(m3);

// Create utility functions for common queries
// Function to find related memories
// Function to get conversation thread
// Function to find memories by category and time range
