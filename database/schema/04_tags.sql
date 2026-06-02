-- ======================================================
-- TAGS AND SEARCH DOMAIN
-- ======================================================

-- Tags (hashtags)
CREATE TABLE tags (
    tag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag_name VARCHAR(100) NOT NULL UNIQUE,
    posts_count BIGINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Post-Tag association
CREATE TABLE post_tags (
    post_id UUID NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

-- Full-text search table
CREATE TABLE post_search (
    post_id UUID PRIMARY KEY REFERENCES posts(post_id) ON DELETE CASCADE,
    search_vector TSVECTOR
);

-- Indexes
CREATE INDEX idx_tags_name ON tags(tag_name);
CREATE INDEX idx_tags_posts_count ON tags(posts_count DESC);
CREATE INDEX idx_post_tags_tag ON post_tags(tag_id);
CREATE INDEX idx_post_search_vector ON post_search USING GIN (search_vector);

-- Function to update search vector
CREATE OR REPLACE FUNCTION update_post_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO post_search (post_id, search_vector)
    VALUES (NEW.post_id, 
            setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'A'))
    ON CONFLICT (post_id) DO UPDATE
    SET search_vector = EXCLUDED.search_vector;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for search vector
CREATE TRIGGER trigger_update_post_search
    AFTER INSERT OR UPDATE OF content ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_post_search_vector();

-- Function to update tag posts count
CREATE OR REPLACE FUNCTION update_tag_posts_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE tags SET posts_count = posts_count + 1 
        WHERE tag_id = NEW.tag_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE tags SET posts_count = posts_count - 1 
        WHERE tag_id = OLD.tag_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for tag count
CREATE TRIGGER trigger_update_tag_count
    AFTER INSERT OR DELETE ON post_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_posts_count();