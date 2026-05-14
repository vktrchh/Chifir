-- ======================================================
-- FLYWAY MIGRATION V003: PARTITIONING FOR SCALABILITY
-- ======================================================

-- Create partitioned table for posts (example for future migration)
-- Commented until data volume requires it

/*
-- Create parent partitioned table
CREATE TABLE posts_partitioned (LIKE posts INCLUDING INDEXES) PARTITION BY RANGE (created_at);

-- Create monthly partitions
DO $$
DECLARE
    start_date DATE := '2024-01-01';
    end_date DATE := '2026-12-01';
    current_date DATE;
    partition_name TEXT;
BEGIN
    current_date := start_date;
    WHILE current_date <= end_date LOOP
        partition_name := 'posts_' || to_char(current_date, 'YYYY_MM');
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS %I PARTITION OF posts_partitioned
            FOR VALUES FROM (%L) TO (%L)',
            partition_name, current_date, current_date + interval '1 month'
        );
        current_date := current_date + interval '1 month';
    END LOOP;
END $$;
*/

-- Create indexes for partitioned tables
CREATE INDEX IF NOT EXISTS idx_posts_partitioned_user_id ON ONLY posts_partitioned(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_partitioned_created ON ONLY posts_partitioned(created_at DESC);

-- Record migration
INSERT INTO schema_version (version) VALUES ('V003') ON CONFLICT DO NOTHING;