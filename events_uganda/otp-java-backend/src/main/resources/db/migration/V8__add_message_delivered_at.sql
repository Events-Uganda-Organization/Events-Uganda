ALTER TABLE messages ADD COLUMN IF NOT EXISTS delivered_at BIGINT;

CREATE INDEX IF NOT EXISTS idx_messages_delivered_at ON messages(delivered_at);
