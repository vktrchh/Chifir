-- ======================================================
-- CONTENT AND POSTS DOMAIN
-- ======================================================

-- Posts table
CREATE TABLE posts (
    post_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    original_post_id UUID REFERENCES posts(post_id) ON DELETE SET NULL,
    content TEXT,
    is_reblog BOOLEAN DEFAULT false,
    reblog_comment TEXT,
    likes_count BIGINT DEFAULT 0,
    reblogs_count BIGINT DEFAULT 0,
    replies_count BIGINT DEFAULT 0,
    views_count BIGINT DEFAULT 0,
    is_hidden BOOLEAN DEFAULT false,
    hidden_by UUID REFERENCES users(user_id),
    hidden_reason VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Media attachments
CREATE TABLE media_attachments (
    media_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id),
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    media_type VARCHAR(20) NOT NULL, -- image, video, gif, audio
    mime_type VARCHAR(100),
    file_size BIGINT,
    width INT,
    height INT,
    duration_seconds INT,
    alt_text VARCHAR(500),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_posts_user_id ON posts(user_id, created_at DESC);
CREATE INDEX idx_posts_original_post_id ON posts(original_post_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_is_hidden ON posts(is_hidden) WHERE is_hidden = false;
CREATE INDEX idx_media_post_id ON media_attachments(post_id);
CREATE INDEX idx_media_user_id ON media_attachments(user_id);
CREATE INDEX idx_media_thumbnail ON media_attachments(thumbnail_url) WHERE thumbnail_url IS NOT NULL;

-- Trigger for updated_at
CREATE TRIGGER trigger_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();