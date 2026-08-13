CREATE TABLE IF NOT EXISTS message_media (
    id VARCHAR(255) PRIMARY KEY,
    message_id VARCHAR(255) NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    media_type VARCHAR(10) NOT NULL,
    mime_type VARCHAR(50) NOT NULL,
    data BYTEA NOT NULL,
    duration_ms BIGINT,
    created_at BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_message_media_message_id ON message_media(message_id);
