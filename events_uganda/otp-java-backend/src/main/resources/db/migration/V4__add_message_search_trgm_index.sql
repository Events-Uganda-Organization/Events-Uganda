CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_messages_text_trgm ON messages USING GIN (text gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_trgm ON conversations USING GIN (last_message gin_trgm_ops);
