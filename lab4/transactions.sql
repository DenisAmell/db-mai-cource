CREATE TABLE IF NOT EXISTS post_stats (
    post_id    BIGINT PRIMARY KEY REFERENCES posts(id) ON DELETE CASCADE,
    likes_cnt  INT NOT NULL DEFAULT 0
);

INSERT INTO post_stats (post_id, likes_cnt)
SELECT id, 0 FROM posts
ON CONFLICT (post_id) DO NOTHING;

-- Сценарий 1. DIRTY READ

-- T1
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE post_stats SET likes_cnt = 999 WHERE post_id = 1;
-- НЕ делаем COMMIT, оставляем транзакцию открытой

-- T2
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT likes_cnt FROM post_stats WHERE post_id = 1;

COMMIT;

-- T1
ROLLBACK;

-- Сценарий 2. NON-REPEATABLE READ

-- T1
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT likes_cnt FROM post_stats WHERE post_id = 1;  -- => 0

-- T2
BEGIN;
UPDATE post_stats SET likes_cnt = 42 WHERE post_id = 1;
COMMIT;

-- T1
SELECT likes_cnt FROM post_stats WHERE post_id = 1;  -- => 42 
COMMIT;

-- FIX

-- T1
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT likes_cnt FROM post_stats WHERE post_id = 1;  -- => 42

-- T2
BEGIN;
UPDATE post_stats SET likes_cnt = 100 WHERE post_id = 1;
COMMIT;

-- T1
SELECT likes_cnt FROM post_stats WHERE post_id = 1;  -- => 42 
COMMIT;

-- Сценарий 3. PHANTOM READ

-- T1
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT COUNT(*) FROM posts WHERE blog_id = 1;        -- например, 3

-- T2
BEGIN;
INSERT INTO posts (title, content, blog_id, author_id)
VALUES ('Фантомный пост', 'phantom', 1, 2);
COMMIT;

-- T1
SELECT COUNT(*) FROM posts WHERE blog_id = 1;        -- => 4 (фантом)
COMMIT;

-- FIX

-- T1
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*) FROM posts WHERE blog_id = 1;        -- = N

-- T2
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO posts (title, content, blog_id, author_id)
VALUES ('Ещё один фантом', 'phantom-2', 1, 2);
COMMIT;

-- T1
SELECT COUNT(*) FROM posts WHERE blog_id = 1;        -- = N
COMMIT;

-- READ UNCOMMITTED (== READ COMMITTED в PostgreSQL)
BEGIN ISOLATION LEVEL READ UNCOMMITTED;
SELECT current_setting('transaction_isolation');
COMMIT;

-- READ COMMITTED (default)
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT current_setting('transaction_isolation');
COMMIT;

-- REPEATABLE READ
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT current_setting('transaction_isolation');
COMMIT;

-- SERIALIZABLE
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT current_setting('transaction_isolation');
COMMIT;
