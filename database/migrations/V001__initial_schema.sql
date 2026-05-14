-- ======================================================
-- FLYWAY MIGRATION V001: INITIAL SCHEMA
-- ======================================================

-- This migration creates all tables in correct order

-- Run schema files in order
\i ../schema/01_users.sql
\i ../schema/02_posts.sql
\i ../schema/03_social.sql
\i ../schema/04_tags.sql
\i ../schema/05_feed_cache.sql
\i ../schema/06_moderation.sql
\i ../schema/07_analytics.sql
\i ../schema/08_audit.sql

-- Record migration
CREATE TABLE IF NOT EXISTS schema_version (
    version VARCHAR(50) PRIMARY KEY,
    applied_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO schema_version (version) VALUES ('V001') ON CONFLICT DO NOTHING;