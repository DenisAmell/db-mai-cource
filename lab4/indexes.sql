-- Запрос 1: посты, опубликованные за указанный период
-- ДО
EXPLAIN ANALYZE
SELECT id, title, published_at
FROM   posts
WHERE  published_at BETWEEN '2024-03-01' AND '2024-04-01'
ORDER  BY published_at;
-- Planning Time: 0.195 ms Execution Time: 14.516 ms

CREATE INDEX idx_posts_published_at_brin
    ON posts USING BRIN (published_at);

-- ПОСЛЕ
EXPLAIN ANALYZE
SELECT id, title, published_at
FROM   posts
WHERE  published_at BETWEEN '2024-03-01' AND '2024-04-01'
ORDER  BY published_at;
-- Planning Time: 0.308 ms Execution Time: 4.269 ms


ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
DROP INDEX IF EXISTS users_email_key;

-- Запрос 2: поиск пользователя по email
-- ДО
EXPLAIN ANALYZE
SELECT id, username, email
FROM   users
WHERE  email = 'bob@example.com';
-- Planning Time: 0.190 ms Execution Time: 0.870 ms


CREATE INDEX idx_users_email_hash
    ON users USING HASH (email);

-- ПОСЛЕ
EXPLAIN ANALYZE
SELECT id, username, email
FROM   users
WHERE  email = 'bob@example.com';
-- Planning Time: 0.135 ms Execution Time: 0.023 ms


DROP INDEX IF EXISTS users_username_key;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_key;

-- Запрос 3: сортировка пользователей по имени
-- ДО
EXPLAIN ANALYZE
SELECT id, username
FROM   users
ORDER  BY username;
-- Planning Time: 0.079 ms Execution Time: 10.421 ms


CREATE INDEX idx_users_username ON users (username);

-- ПОСЛЕ 
EXPLAIN ANALYZE
SELECT id, username
FROM   users
ORDER  BY username;
-- Planning Time: 0.199 ms Execution Time: 1.947 ms


-- Расширение pg_trgm нужно для триграммного поиска
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Запрос 4: поиск постов по подстроке в заголовке
-- ДО
EXPLAIN ANALYZE
SELECT id, title
FROM   posts
WHERE  title ILIKE '%Docker%';
-- Planning Time: 0.496 ms Execution Time: 57.466 ms

CREATE INDEX idx_posts_title_trgm
    ON posts USING GIN (title gin_trgm_ops);

-- ПОСЛЕ
EXPLAIN ANALYZE
SELECT id, title
FROM   posts
WHERE  title ILIKE '%Docker%';
-- Planning Time: 0.214 ms Execution Time: 7.654 ms


-- Запрос 5: последние посты конкретного блога
-- ДО
EXPLAIN ANALYZE
SELECT id, title, published_at
FROM   posts
WHERE  blog_id = 4
ORDER  BY published_at DESC
LIMIT  5;
-- Planning Time: 0.111 ms Execution Time: 8.834 ms


CREATE INDEX idx_posts_blog_published ON posts (blog_id, published_at DESC);

-- ПОСЛЕ 
EXPLAIN ANALYZE
SELECT id, title, published_at
FROM   posts
WHERE  blog_id = 4
ORDER  BY published_at DESC
LIMIT  5;
-- Planning Time: 0.464 ms Execution Time: 0.161 ms


-- Запрос 6: пост со счётчиками комментариев и лайков
-- ДО
EXPLAIN ANALYZE
SELECT p.id,
       p.title,
       COUNT(DISTINCT c.id) AS comments_cnt,
       COUNT(DISTINCT l.id) AS likes_cnt
FROM   posts p
LEFT JOIN comments c ON c.post_id = p.id
LEFT JOIN likes    l ON l.post_id = p.id
GROUP  BY p.id, p.title
ORDER  BY likes_cnt DESC;
-- Planning Time: 0.896 ms Execution Time: 388.479 ms

CREATE INDEX idx_comments_post_id ON comments (post_id);
CREATE INDEX idx_likes_post_id    ON likes    (post_id);

-- ПОСЛЕ
EXPLAIN ANALYZE
SELECT p.id,
       p.title,
       COUNT(DISTINCT c.id) AS comments_cnt,
       COUNT(DISTINCT l.id) AS likes_cnt
FROM   posts p
LEFT JOIN comments c ON c.post_id = p.id
LEFT JOIN likes    l ON l.post_id = p.id
GROUP  BY p.id, p.title
ORDER  BY likes_cnt DESC;
-- Planning Time: 0.231 ms Execution Time: 370.437 ms