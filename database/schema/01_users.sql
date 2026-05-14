-- ======================================================
-- USER MANAGEMENT DOMAIN
-- ======================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (core)
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100),
    avatar_url TEXT,
    bio VARCHAR(500),
    website VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    role VARCHAR(20) DEFAULT 'user', -- user, moderator, admin
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ -- soft delete
);

-- User sessions for auth
CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    user_agent TEXT,
    ip_address INET
);

-- User settings
CREATE TABLE user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'en',
    theme VARCHAR(20) DEFAULT 'light',
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    show_activity_status BOOLEAN DEFAULT true,
    allow_messages BOOLEAN DEFAULT true
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role) WHERE is_active = true;
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON user_sessions(expires_at);
CREATE INDEX idx_user_settings_language ON user_settings(language);

-- Triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert system user
INSERT INTO users (user_id, email, password_hash, username, display_name, role, is_verified)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'system@microblog.local',
    'SYSTEM_USER_NO_LOGIN',
    'system',
    'System User',
    'admin',
    true
) ON CONFLICT DO NOTHING;