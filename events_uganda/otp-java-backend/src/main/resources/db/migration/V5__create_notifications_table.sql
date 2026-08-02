CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    category VARCHAR(50),
    read_at BIGINT,
    archived_at BIGINT,
    created_at BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_active ON notifications(user_id) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_user_archived ON notifications(user_id) WHERE archived_at IS NOT NULL;
