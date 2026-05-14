-- ======================================================
-- MODERATION DOMAIN
-- ======================================================

-- Moderation actions log
CREATE TABLE moderation_log (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    moderator_id UUID NOT NULL REFERENCES users(user_id),
    target_type VARCHAR(20) NOT NULL, -- 'post', 'user', 'comment'
    target_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL, -- 'hide', 'restore', 'ban', 'warn'
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reports from users
CREATE TABLE reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES users(user_id),
    target_type VARCHAR(20) NOT NULL, -- 'post', 'user'
    target_id UUID NOT NULL,
    reason VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, reviewed, dismissed, actioned
    resolved_by UUID REFERENCES users(user_id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_moderation_target ON moderation_log(target_type, target_id);
CREATE INDEX idx_moderation_moderator ON moderation_log(moderator_id, created_at DESC);
CREATE INDEX idx_moderation_created ON moderation_log(created_at DESC);
CREATE INDEX idx_reports_target ON reports(target_type, target_id);
CREATE INDEX idx_reports_status ON reports(status, created_at DESC);
CREATE INDEX idx_reports_reporter ON reports(reporter_id);
CREATE INDEX idx_reports_created ON reports(created_at DESC);

-- Function to hide post
CREATE OR REPLACE FUNCTION hide_post(p_post_id UUID, p_moderator_id UUID, p_reason TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE posts 
    SET is_hidden = true, 
        hidden_by = p_moderator_id, 
        hidden_reason = p_reason,
        updated_at = NOW()
    WHERE post_id = p_post_id;
    
    INSERT INTO moderation_log (moderator_id, target_type, target_id, action, reason)
    VALUES (p_moderator_id, 'post', p_post_id, 'hide', p_reason);
END;
$$ LANGUAGE plpgsql;

-- Function to restore post
CREATE OR REPLACE FUNCTION restore_post(p_post_id UUID, p_moderator_id UUID, p_reason TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE posts 
    SET is_hidden = false, 
        hidden_by = NULL, 
        hidden_reason = NULL,
        updated_at = NOW()
    WHERE post_id = p_post_id;
    
    INSERT INTO moderation_log (moderator_id, target_type, target_id, action, reason)
    VALUES (p_moderator_id, 'post', p_post_id, 'restore', p_reason);
END;
$$ LANGUAGE plpgsql;