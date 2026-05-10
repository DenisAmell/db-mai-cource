
CREATE VIEW blog_stats AS
SELECT
    b.id                            AS blog_id,
    b.title                         AS blog_title,
    u.username                      AS owner_username,
    b.created_at                    AS blog_created,
    COUNT(DISTINCT p.id)            AS total_posts,
    COUNT(DISTINCT s.subscriber_id) AS total_subscribers,
    COUNT(DISTINCT l.id)            AS total_likes,
    MAX(p.published_at)             AS last_post_date
FROM blogs b
LEFT JOIN users         u ON b.owner_id = u.id
LEFT JOIN posts         p ON b.id       = p.blog_id
LEFT JOIN subscriptions s ON b.id       = s.blog_id
LEFT JOIN likes         l ON p.id       = l.post_id
GROUP BY b.id, b.title, u.username, b.created_at;


CREATE VIEW user_activity AS
SELECT
    u.id                 AS user_id,
    u.username,
    u.email,
    u.created_at         AS registered_at,
    COUNT(DISTINCT b.id) AS blogs_count,
    COUNT(DISTINCT p.id) AS posts_count,
    COUNT(DISTINCT c.id) AS comments_count,
    COUNT(DISTINCT lk.id) AS likes_given
FROM users u
LEFT JOIN blogs    b  ON u.id = b.owner_id
LEFT JOIN posts    p  ON u.id = p.author_id
LEFT JOIN comments c  ON u.id = c.user_id
LEFT JOIN likes    lk ON u.id = lk.user_id
GROUP BY u.id, u.username, u.email, u.created_at;


CREATE VIEW post_details AS
SELECT
    p.id                 AS post_id,
    p.title              AS post_title,
    b.title              AS blog_title,
    u.username           AS author,
    p.published_at,
    COUNT(DISTINCT c.id) AS comment_count,
    COUNT(DISTINCT l.id) AS like_count
FROM posts p
INNER JOIN blogs b ON p.blog_id   = b.id
INNER JOIN users u ON p.author_id = u.id
LEFT JOIN comments c ON p.id      = c.post_id
LEFT JOIN likes    l ON p.id      = l.post_id
GROUP BY p.id, p.title, b.title, u.username, p.published_at;
