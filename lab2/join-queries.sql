-- 1. Все посты с названием блога и именем автора 
SELECT
    p.id                AS post_id,
    p.title             AS post_title,
    b.title             AS blog_title,
    u.username          AS author,
    p.published_at
FROM posts p
INNER JOIN blogs b ON p.blog_id   = b.id
INNER JOIN users u ON p.author_id = u.id
ORDER BY p.published_at DESC;

-- 2. Все пользователи и их блоги, включая тех, у кого нет блога
SELECT
    u.username,
    u.email,
    b.title      AS blog_title,
    b.created_at AS blog_created
FROM users u
LEFT JOIN blogs b ON u.id = b.owner_id
ORDER BY u.username;

-- 3. Посты с количеством комментариев и лайков
SELECT
    p.id                       AS post_id,
    p.title                    AS post_title,
    COUNT(DISTINCT c.id)       AS comment_count,
    COUNT(DISTINCT l.id)       AS like_count
FROM posts p
LEFT JOIN comments c ON p.id = c.post_id
LEFT JOIN likes    l ON p.id = l.post_id
GROUP BY p.id, p.title
ORDER BY like_count DESC, comment_count DESC;

-- 4. Подписчики с блогами и владельцами блогов
SELECT
    u.username       AS subscriber,
    b.title          AS blog_title,
    owner.username   AS blog_owner,
    s.subscribed_at
FROM subscriptions s
INNER JOIN users u     ON s.subscriber_id = u.id
INNER JOIN blogs b     ON s.blog_id       = b.id
INNER JOIN users owner ON b.owner_id      = owner.id
ORDER BY u.username, b.title;

-- 5. Комментарии с именем автора и заголовком поста
SELECT
    c.id            AS comment_id,
    u.username      AS commenter,
    p.title         AS post_title,
    c.text,
    c.created_at
FROM comments c
INNER JOIN users u ON c.user_id = u.id
INNER JOIN posts p ON c.post_id = p.id
ORDER BY c.created_at DESC;

-- 6. Сводка по блогам: владелец, постов, лайков, подписчиков
SELECT
    b.id                          AS blog_id,
    b.title                       AS blog_title,
    u.username                    AS owner,
    COUNT(DISTINCT p.id)          AS total_posts,
    COUNT(DISTINCT l.id)          AS total_likes,
    COUNT(DISTINCT s.subscriber_id) AS total_subscribers
FROM blogs b
LEFT JOIN users         u ON b.owner_id  = u.id
LEFT JOIN posts         p ON b.id        = p.blog_id
LEFT JOIN likes         l ON p.id        = l.post_id
LEFT JOIN subscriptions s ON b.id        = s.blog_id
GROUP BY b.id, b.title, u.username
ORDER BY total_likes DESC;
