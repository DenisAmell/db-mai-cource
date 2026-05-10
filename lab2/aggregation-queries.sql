-- 1. Количество постов в каждом блоге
SELECT
    b.title          AS blog_title,
    COUNT(p.id)      AS post_count
FROM blogs b
LEFT JOIN posts p ON b.id = p.blog_id
GROUP BY b.id, b.title
ORDER BY post_count DESC;

-- 2. Посты с более чем 2 лайками
SELECT
    p.title        AS post_title,
    COUNT(l.id)    AS like_count
FROM posts p
LEFT JOIN likes l ON p.id = l.post_id
GROUP BY p.id, p.title
HAVING COUNT(l.id) > 2
ORDER BY like_count DESC;

-- 3. Суммарное количество лайков по блогам 
SELECT
    b.title          AS blog_title,
    COUNT(l.id)      AS total_likes
FROM blogs b
JOIN posts p ON b.id = p.blog_id
LEFT JOIN likes l ON p.id = l.post_id
GROUP BY b.id, b.title
ORDER BY total_likes DESC;

-- 4. Среднее количество комментариев на пост по каждому блогу 
SELECT
    b.title                           AS blog_title,
    ROUND(AVG(comment_counts.cnt), 2) AS avg_comments_per_post
FROM blogs b
JOIN posts p ON b.id = p.blog_id
JOIN (
    SELECT post_id, COUNT(*) AS cnt
    FROM comments
    GROUP BY post_id
) AS comment_counts ON p.id = comment_counts.post_id
GROUP BY b.id, b.title
ORDER BY avg_comments_per_post DESC;

-- 5. Количество подписчиков у каждого блога
SELECT
    b.title                    AS blog_title,
    COUNT(s.subscriber_id)     AS subscriber_count
FROM blogs b
LEFT JOIN subscriptions s ON b.id = s.blog_id
GROUP BY b.id, b.title
ORDER BY subscriber_count DESC;

-- 6. Дата первого и последнего поста в каждом блоге
SELECT
    b.title              AS blog_title,
    MIN(p.published_at)  AS first_post_date,
    MAX(p.published_at)  AS last_post_date
FROM blogs b
JOIN posts p ON b.id = p.blog_id
GROUP BY b.id, b.title
ORDER BY b.title;

-- 7. Самые активные авторы: число постов и комментариев 
SELECT
    u.username,
    COUNT(DISTINCT p.id) AS posts_written,
    COUNT(DISTINCT c.id) AS comments_written,
    COUNT(DISTINCT p.id) + COUNT(DISTINCT c.id) AS total_activity
FROM users u
LEFT JOIN posts    p ON u.id = p.author_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
ORDER BY total_activity DESC;

-- 8. Блоги, у которых суммарное число лайков превышает 5
SELECT
    b.title       AS blog_title,
    COUNT(l.id)   AS total_likes
FROM blogs b
JOIN posts p ON b.id = p.blog_id
LEFT JOIN likes l ON p.id = l.post_id
GROUP BY b.id, b.title
HAVING COUNT(l.id) > 5
ORDER BY total_likes DESC;
