-- ======================================================
-- ANALYTICS & STATISTICS DOMAIN
-- ======================================================

-- Daily user activity
CREATE TABLE daily_user_activity (
    activity_date DATE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    posts_created INT DEFAULT 0,
    likes_given INT DEFAULT 0,
    reblogs_done INT DEFAULT 0,
    follows_created INT DEFAULT 0,
    session_duration_seconds INT DEFAULT 0,
    PRIMARY KEY (activity_date, user_id)
);

-- Post daily stats
CREATE TABLE post_daily_stats (
    stat_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,
    likes_count INT DEFAULT 0,
    reblogs_count INT DEFAULT 0,
    replies_count INT DEFAULT 0,
    views_count INT DEFAULT 0,
    engagement_rate DECIMAL(5,4)
);

-- Platform daily metrics
CREATE TABLE platform_daily_metrics (
    metric_date DATE PRIMARY KEY,
    total_active_users INT DEFAULT 0,
    new_users INT DEFAULT 0,
    total_posts INT DEFAULT 0,
    total_likes INT DEFAULT 0,
    total_reblogs INT DEFAULT 0,
    avg_session_duration_seconds INT DEFAULT 0,
    peak_concurrent_users INT DEFAULT 0
);

-- Indexes
CREATE INDEX idx_daily_activity_date ON daily_user_activity(activity_date DESC);
CREATE INDEX idx_daily_activity_user ON daily_user_activity(user_id, activity_date DESC);
CREATE INDEX idx_post_stats_date ON post_daily_stats(post_id, stat_date DESC);
CREATE INDEX idx_post_stats_post ON post_daily_stats(post_id);
CREATE INDEX idx_platform_metrics_date ON platform_daily_metrics(metric_date DESC);

-- Function to update daily user activity
CREATE OR REPLACE FUNCTION update_daily_activity()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO daily_user_activity (activity_date, user_id, posts_created)
    VALUES (CURRENT_DATE, NEW.user_id, 1)
    ON CONFLICT (activity_date, user_id) 
    DO UPDATE SET posts_created = daily_user_activity.posts_created + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for post activity
CREATE TRIGGER trigger_daily_post_activity
    AFTER INSERT ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_activity();

-- Function to aggregate platform metrics
CREATE OR REPLACE FUNCTION aggregate_platform_metrics(p_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO platform_daily_metrics (metric_date, total_active_users, new_users, total_posts, total_likes, total_reblogs)
    SELECT 
        p_date,
        COUNT(DISTINCT dau.user_id),
        COUNT(DISTINCT u.user_id) FILTER (WHERE DATE(u.created_at) = p_date),
        COUNT(DISTINCT p.post_id),
        COUNT(DISTINCT l.like_id),
        COUNT(DISTINCT p2.post_id) FILTER (WHERE p2.is_reblog = true)
    FROM daily_user_activity dau
    CROSS JOIN users u
    CROSS JOIN posts p
    CROSS JOIN likes l
    CROSS JOIN posts p2
    WHERE dau.activity_date = p_date
        AND DATE(u.created_at) = p_date
        AND DATE(p.created_at) = p_date
        AND DATE(l.created_at) = p_date
        AND DATE(p2.created_at) = p_date
        AND p2.is_reblog = true
    GROUP BY p_date;
END;
$$ LANGUAGE plpgsql;