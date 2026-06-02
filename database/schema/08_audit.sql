-- ======================================================
-- AUDIT & LOGGING DOMAIN
-- ======================================================

-- Audit log for compliance
CREATE TABLE audit_log (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    old_value JSONB,
    new_value JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User profile view (for public profiles)
CREATE VIEW user_profiles AS
SELECT 
    u.user_id,
    u.username,
    u.display_name,
    u.avatar_url,
    u.bio,
    u.website,
    u.created_at,
    u.is_verified,
    COUNT(DISTINCT f1.follower_id) as followers_count,
    COUNT(DISTINCT f2.following_id) as following_count,
    COUNT(DISTINCT p.post_id) as posts_count
FROM users u
LEFT JOIN follows f1 ON f1.following_id = u.user_id
LEFT JOIN follows f2 ON f2.follower_id = u.user_id
LEFT JOIN posts p ON p.user_id = u.user_id AND p.is_hidden = false
WHERE u.is_active = true AND u.deleted_at IS NULL AND u.role != 'admin'
GROUP BY u.user_id;

-- Indexes
CREATE INDEX idx_audit_user ON audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id, created_at DESC);
CREATE INDEX idx_audit_action ON audit_log(action, created_at DESC);
CREATE INDEX idx_audit_created ON audit_log(created_at DESC);

-- Function to log audit events
CREATE OR REPLACE FUNCTION log_audit_event(
    p_user_id UUID,
    p_action VARCHAR,
    p_entity_type VARCHAR,
    p_entity_id UUID,
    p_old_value JSONB DEFAULT NULL,
    p_new_value JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO audit_log (user_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent)
    VALUES (p_user_id, p_action, p_entity_type, p_entity_id, p_old_value, p_new_value, p_ip_address, p_user_agent)
    RETURNING log_id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;