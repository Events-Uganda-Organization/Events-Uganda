CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(255),
    photo_url VARCHAR(255),
    auth_provider VARCHAR(255) NOT NULL,
    created_at BIGINT NOT NULL,
    referral_code VARCHAR(10) UNIQUE,
    referred_by VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS otps (
    id BIGSERIAL PRIMARY KEY,
    identifier VARCHAR(255) NOT NULL,
    otp_code VARCHAR(255) NOT NULL,
    created_at BIGINT NOT NULL
);
