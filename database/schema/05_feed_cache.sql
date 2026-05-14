-- ======================================================
-- FEED CACHE DOMAIN
-- ======================================================

-- Feed cache table (persistent backup for feed)
CREATE TABLE user_feeds_cache (
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    author_username VARCHAR(50),
    author_avatar_url TEXT,
    post_content TEXT,
    post_created_at TIMESTAMPTZ,
    feed_position BIGINT DEFAULT 0,
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

-- Indexes
CREATE INDEX idx_feeds_user_position ON user_feeds_cache(user_id, feed_position DESC);
CREATE INDEX idx_feeds_cached_at ON user_feeds_cache(cached_at DESC);
CREATE INDEX idx_feeds_post ON user_feeds_cache(post_id);

-- View for user feed
CREATE OR REPLACE VIEW user_feed_view AS
SELECT 
    p.post_id,
    p.user_id as author_id,
    u.username as author_username,
    u.display_name as author_display_name,
    u.avatar_url as author_avatar,
    p.content,
    p.is_reblog,
    p.reblog_comment,
    p.original_post_id,
    p.likes_count,
    p.reblogs_count,
    p.replies_count,
    p.created_at,
    array_agg(DISTINCT t.tag_name) as tags,
    array_agg(DISTINCT m.thumbnail_url) FILTER (WHERE m.thumbnail_url IS NOT NULL) as media_urls
FROM posts p
JOIN users u ON u.user_id = p.user_id
LEFT JOIN post_tags pt ON pt.post_id = p.post_id
LEFT JOIN tags t ON t.tag_id = pt.tag_id
LEFT JOIN media_attachments m ON m.post_id = p.post_id
WHERE p.is_hidden = false
GROUP BY p.post_id, u.user_id, u.username, u.display_name, u.avatar_url;

-- Function to refresh feed cache for a user
CREATE OR REPLACE FUNCTION refresh_user_feed_cache(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    DELETE FROM user_feeds_cache WHERE user_id = p_user_id;
    
    INSERT INTO user_feeds_cache (user_id, post_id, author_username, author_avatar_url, post_content, post_created_at, feed_position)
    SELECT 
        p_user_id,
        p.post_id,
        u.username,
        u.avatar_url,
        p.content,
        p.created_at,
        ROW_NUMBER() OVER (ORDER BY p.created_at DESC)
    FROM posts p
    JOIN users u ON u.user_id = p.user_id
    JOIN follows f ON f.following_id = p.user_id
    WHERE f.follower_id = p_user_id
        AND p.is_hidden = false
    ORDER BY p.created_at DESC
    LIMIT 1000;
END;
$$ LANGUAGE plpgsql;