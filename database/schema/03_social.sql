-- ======================================================
-- SOCIAL INTERACTIONS DOMAIN
-- ======================================================

-- Follows (subscription graph)
CREATE TABLE follows (
    follow_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- Likes
CREATE TABLE likes (
    like_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

-- Blocks
CREATE TABLE blocks (
    block_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

-- Mutes
CREATE TABLE mutes (
    mute_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    muter_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    muted_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(muter_id, muted_id)
);

-- Indexes
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);
CREATE INDEX idx_follows_following_created ON follows(following_id, created_at DESC);
CREATE INDEX idx_likes_post_id ON likes(post_id);
CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_likes_post_user ON likes(post_id, user_id);
CREATE INDEX idx_likes_created_at ON likes(created_at);
CREATE INDEX idx_blocks_blocker ON blocks(blocker_id);
CREATE INDEX idx_blocks_blocked ON blocks(blocked_id);
CREATE INDEX idx_mutes_muter ON mutes(muter_id);
CREATE INDEX idx_mutes_muted ON mutes(muted_id);

-- Function to update post likes count
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET likes_count = likes_count + 1 
        WHERE post_id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET likes_count = likes_count - 1 
        WHERE post_id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for likes count
CREATE TRIGGER trigger_update_likes_count
    AFTER INSERT OR DELETE ON likes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_likes_count();