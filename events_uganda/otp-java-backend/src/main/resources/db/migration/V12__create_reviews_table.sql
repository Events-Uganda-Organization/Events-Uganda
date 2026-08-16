CREATE TABLE IF NOT EXISTS reviews (
    id VARCHAR(255) PRIMARY KEY,
    service_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    rating INT NOT NULL,
    review_text TEXT,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    CONSTRAINT uq_reviews_user_service UNIQUE (user_id, service_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_service_id ON reviews(service_id);
