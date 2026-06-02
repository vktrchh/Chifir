-- ======================================================
-- POST COUNTS MANAGEMENT FUNCTIONS
-- ======================================================

-- Update all post counts (for data repair)
CREATE OR REPLACE FUNCTION recalc_all_post_counts()
RETURNS VOID AS $$
BEGIN
    -- Recalculate likes count
    UPDATE posts p
    SET likes_count = (
        SELECT COUNT(*) 
        FROM likes l 
        WHERE l.post_id = p.post_id
    );
    
    -- Recalculate reblogs count
    UPDATE posts p
    SET reblogs_count = (
        SELECT COUNT(*) 
        FROM posts r 
        WHERE r.original_post_id = p.post_id AND r.is_reblog = true
    );
    
    RAISE NOTICE 'All post counts recalculated';
END;
$$ LANGUAGE plpgsql;

-- Update single post counts
CREATE OR REPLACE FUNCTION update_post_counts(p_post_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE posts 
    SET likes_count = (SELECT COUNT(*) FROM likes WHERE post_id = p_post_id),
        reblogs_count = (SELECT COUNT(*) FROM posts WHERE original_post_id = p_post_id AND is_reblog = true)
    WHERE post_id = p_post_id;
END;
$$ LANGUAGE plpgsql;