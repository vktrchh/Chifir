# Database Schema for Microblogging Social Network

## Overview
PostgreSQL 15+ database schema for a microblogging platform supporting 1M DAU with AP (Availability > Consistency) characteristics.

## Requirements Met
-  User registration & authentication with hashed passwords
-  Multimedia posts with media attachments
-  Follow/Unfollow (subscription graph)
-  Likes & Reblogs with async processing
-  Tag-based search with full-text search
-  Moderation tools (RBAC)
-  User profiles
-  Feed generation support

## Performance Targets
| Metric | Value |
|--------|-------|
| Write RPS | 25 |
| Read RPS | 2,500 |
| Storage 1 year | 1.1 PB |
| Storage 5 years | 6 PB |

## Quick Start

```bash
# Create database
createdb -U postgres microblog_db

# Run all schemas in order
psql -U postgres -d microblog_db -f 01_users.sql
psql -U postgres -d microblog_db -f 02_posts.sql
psql -U postgres -d microblog_db -f 03_social.sql
psql -U postgres -d microblog_db -f 04_tags.sql
psql -U postgres -d microblog_db -f 05_feed_cache.sql
psql -U postgres -d microblog_db -f 06_moderation.sql
psql -U postgres -d microblog_db -f 07_analytics.sql
psql -U postgres -d microblog_db -f 08_audit.sql

# Run migrations
psql -U postgres -d microblog_db -f ../migrations/V001__initial_schema.sql