-- Запрос 1: Топ-5 самых популярных постов с автором и блогом
EXPLAIN ANALYZE
SELECT p.id,
       p.title,
       u.username        AS author,
       b.title           AS blog_title,
       COUNT(l.id)       AS like_count
FROM   posts p
INNER  JOIN users u ON u.id = p.author_id
INNER  JOIN blogs b ON b.id = p.blog_id
LEFT   JOIN likes l ON l.post_id = p.id
WHERE  p.published_at BETWEEN '2024-02-01' AND '2024-04-30'
GROUP  BY p.id, p.title, u.username, b.title
ORDER  BY like_count DESC
LIMIT  5;

-- Запрос 2: Активность пользователей: блоги, посты, комментарии, лайки
EXPLAIN ANALYZE
SELECT u.id,
       u.username,
       COUNT(DISTINCT b.id) AS blogs_cnt,
       COUNT(DISTINCT p.id) AS posts_cnt,
       COUNT(DISTINCT c.id) AS comments_cnt,
       COUNT(DISTINCT l.id) AS likes_cnt
FROM   users u
LEFT   JOIN blogs    b ON b.owner_id  = u.id
LEFT   JOIN posts    p ON p.author_id = u.id
LEFT   JOIN comments c ON c.user_id   = u.id
LEFT   JOIN likes    l ON l.user_id   = u.id
GROUP  BY u.id, u.username
ORDER  BY posts_cnt DESC, likes_cnt DESC;

-- Запрос 3: Поиск постов конкретного блога по подстроке в заголовке
EXPLAIN ANALYZE
SELECT id, title, published_at
FROM   posts
WHERE  blog_id = 4
  AND  title ILIKE '%Docker%'
ORDER  BY published_at DESC;


-- Запрос 4: Лента подписчика — посты из блогов, на которые он подписан
EXPLAIN ANALYZE
SELECT p.id,
       p.title,
       b.title         AS blog_title,
       p.published_at
FROM   subscriptions s
INNER  JOIN blogs b ON b.id = s.blog_id
INNER  JOIN posts p ON p.blog_id = b.id
WHERE  s.subscriber_id = 1
ORDER  BY p.published_at DESC
LIMIT  10;


-- Запрос 5: Сводный рейтинг блогов
EXPLAIN ANALYZE
SELECT b.id,
       b.title,
       COUNT(DISTINCT p.id)            AS posts_cnt,
       COUNT(DISTINCT l.id)            AS likes_cnt,
       COUNT(DISTINCT s.subscriber_id) AS subs_cnt
FROM   blogs b
LEFT   JOIN posts         p ON p.blog_id = b.id
LEFT   JOIN likes         l ON l.post_id = p.id
LEFT   JOIN subscriptions s ON s.blog_id = b.id
GROUP  BY b.id, b.title
ORDER  BY likes_cnt DESC, subs_cnt DESC;
