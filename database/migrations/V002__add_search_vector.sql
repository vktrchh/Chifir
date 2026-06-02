-- ======================================================
-- FLYWAY MIGRATION V002: SEARCH VECTOR IMPROVEMENTS
-- ======================================================

-- Add full-text search for multiple languages
ALTER TABLE post_search ADD COLUMN IF NOT EXISTS search_vector_ru TSVECTOR;
ALTER TABLE post_search ADD COLUMN IF NOT EXISTS search_vector_tr TSVECTOR;

-- Create composite GIN index
CREATE INDEX IF NOT EXISTS idx_post_search_composite 
ON post_search USING GIN (search_vector, search_vector_ru, search_vector_tr);

-- Update trigger for multiple languages
CREATE OR REPLACE FUNCTION update_post_search_vector_multilang()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO post_search (post_id, search_vector, search_vector_ru, search_vector_tr)
    VALUES (
        NEW.post_id,
        setweight(to_tsvector('english', COALESCE(NEW.content, '')), 'A'),
        setweight(to_tsvector('russian', COALESCE(NEW.content, '')), 'A'),
        setweight(to_tsvector('turkish', COALESCE(NEW.content, '')), 'A')
    )
    ON CONFLICT (post_id) DO UPDATE
    SET search_vector = EXCLUDED.search_vector,
        search_vector_ru = EXCLUDED.search_vector_ru,
        search_vector_tr = EXCLUDED.search_vector_tr;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_post_search ON posts;
CREATE TRIGGER trigger_update_post_search
    AFTER INSERT OR UPDATE OF content ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_post_search_vector_multilang();