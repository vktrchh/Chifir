CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
                       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                       email VARCHAR(255) NOT NULL UNIQUE,
                       username VARCHAR(50) NOT NULL UNIQUE,
                       password_hash VARCHAR(255) NOT NULL,

                       display_name VARCHAR(100),
                       avatar_url TEXT,
                       bio TEXT,

                       role VARCHAR(30) NOT NULL DEFAULT 'USER',

                       is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
                       is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

                       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
                       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                       author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

                       content TEXT NOT NULL,
                       image_url TEXT,

                       original_post_id UUID REFERENCES posts(id) ON DELETE SET NULL,

                       likes_count BIGINT NOT NULL DEFAULT 0,
                       reblogs_count BIGINT NOT NULL DEFAULT 0,
                       comments_count BIGINT NOT NULL DEFAULT 0,

                       is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
                       is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

                       created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE follows (
                         id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                         follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                         following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

                         created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                         CONSTRAINT uq_follows_pair UNIQUE (follower_id, following_id),
                         CONSTRAINT chk_no_self_follow CHECK (follower_id <> following_id)
);

CREATE TABLE post_likes (
                            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                            post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,

                            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                            CONSTRAINT uq_post_likes_pair UNIQUE (user_id, post_id)
);

CREATE TABLE tags (
                      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                      name VARCHAR(50) NOT NULL UNIQUE,

                      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post_tags (
                           post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
                           tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,

                           PRIMARY KEY (post_id, tag_id)
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_follows_follower_id ON follows(follower_id);
CREATE INDEX idx_follows_following_id ON follows(following_id);
CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);
CREATE INDEX idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX idx_tags_name ON tags(name);