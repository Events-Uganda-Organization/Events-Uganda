CREATE TABLE IF NOT EXISTS calls (
    id VARCHAR(255) PRIMARY KEY,
    caller_id VARCHAR(255) NOT NULL,
    callee_id VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL,
    started_at BIGINT,
    ended_at BIGINT,
    duration_ms BIGINT,
    created_at BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_calls_caller_id ON calls(caller_id);
CREATE INDEX IF NOT EXISTS idx_calls_callee_id ON calls(callee_id);
