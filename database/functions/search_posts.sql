-- ======================================================
-- SEARCH FUNCTIONS
-- ======================================================

-- Search posts by keyword (English)
CREATE OR REPLACE FUNCTION search_posts_english(
    search_query TEXT,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE(
    post_id UUID,
    content TEXT,
    author_username VARCHAR,
    author_avatar TEXT,
    created_at TIMESTAMPTZ,
    relevance REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.post_id,
        p.content,
        u.username,
        u.avatar_url,
        p.created_at,
        ts_rank(ps.search_vector, plainto_tsquery('english', search_query)) as relevance
    FROM posts p
    JOIN users u ON u.user_id = p.user_id
    JOIN post_search ps ON ps.post_id = p.post_id
    WHERE ps.search_vector @@ plainto_tsquery('english', search_query)
        AND p.is_hidden = false
    ORDER BY relevance DESC, p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Search posts by tag
CREATE OR REPLACE FUNCTION search_posts_by_tag(
    tag_name_input VARCHAR,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE(
    post_id UUID,
    content TEXT,
    author_username VARCHAR,
    author_avatar TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.post_id,
        p.content,
        u.username,
        u.avatar_url,
        p.created_at
    FROM posts p
    JOIN users u ON u.user_id = p.user_id
    JOIN post_tags pt ON pt.post_id = p.post_id
    JOIN tags t ON t.tag_id = pt.tag_id
    WHERE t.tag_name = tag_name_input
        AND p.is_hidden = false
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;