ALTER TABLE posts          DISABLE TRIGGER USER;
ALTER TABLE subscriptions  DISABLE TRIGGER USER;

TRUNCATE TABLE
    posts_audit,
    subscriptions,
    likes,
    comments,
    posts,
    blogs,
    users
RESTART IDENTITY CASCADE;

INSERT INTO users (username, email, created_at)
SELECT
    'user_' || g,
    'user_' || g || '@example.com',
    TIMESTAMP '2023-01-01' + (random() * INTERVAL '730 days')
FROM generate_series(1, 5000) g;


INSERT INTO blogs (title, description, owner_id, created_at)
SELECT
    'Блог №' || g,
    'Описание блога номер ' || g,
    1 + (random() * 4999)::int,
    TIMESTAMP '2023-01-01' + (random() * INTERVAL '700 days')
FROM generate_series(1, 1000) g;


WITH dated_posts AS (
    SELECT
        g,
        1 + (random() * 999)::int                                   AS bid,
        TIMESTAMP '2023-01-01' + (g * INTERVAL '10 minutes')        AS pub_at
    FROM generate_series(1, 100000) g
)
INSERT INTO posts (title, content, blog_id, author_id, published_at)
SELECT
    CASE (dp.g % 50)
        WHEN 0  THEN 'Docker для начинающих #' || dp.g
        WHEN 1  THEN 'Полное руководство по Docker #' || dp.g
        WHEN 5  THEN 'Python и машинное обучение #' || dp.g
        WHEN 10 THEN 'Кулинарные рецепты выпуск #' || dp.g
        WHEN 15 THEN 'Путешествие по Японии часть #' || dp.g
        WHEN 20 THEN 'Микросервисы на практике #' || dp.g
        WHEN 25 THEN 'JavaScript: тонкости #' || dp.g
        WHEN 30 THEN 'Обзор фотокамеры #' || dp.g
        ELSE        'Пост номер ' || dp.g
    END,
    'Содержимое поста номер ' || dp.g || '. Lorem ipsum dolor sit amet.',
    dp.bid,
    b.owner_id,
    dp.pub_at
FROM dated_posts dp
JOIN blogs b ON b.id = dp.bid;


INSERT INTO comments (text, user_id, post_id, created_at)
SELECT
    'Комментарий №' || g || ' — интересный материал!',
    1 + (random() * 4999)::int,
    1 + (random() * 99999)::int,
    TIMESTAMP '2023-01-01' + (random() * INTERVAL '730 days')
FROM generate_series(1, 200000) g;


INSERT INTO likes (user_id, post_id, created_at)
SELECT
    1 + (random() * 4999)::int,
    1 + (random() * 99999)::int,
    TIMESTAMP '2023-01-01' + (random() * INTERVAL '730 days')
FROM generate_series(1, 300000) g
ON CONFLICT (user_id, post_id) DO NOTHING;


INSERT INTO subscriptions (subscriber_id, blog_id, subscribed_at)
SELECT
    1 + (random() * 4999)::int,
    1 + (random() * 999)::int,
    TIMESTAMP '2023-01-01' + (random() * INTERVAL '730 days')
FROM generate_series(1, 20000) g
ON CONFLICT (subscriber_id, blog_id) DO NOTHING;


ALTER TABLE posts          ENABLE TRIGGER USER;
ALTER TABLE subscriptions  ENABLE TRIGGER USER;


SELECT 'users'         AS table_name, COUNT(*) AS rows FROM users
UNION ALL SELECT 'blogs',        COUNT(*) FROM blogs
UNION ALL SELECT 'posts',        COUNT(*) FROM posts
UNION ALL SELECT 'comments',     COUNT(*) FROM comments
UNION ALL SELECT 'likes',        COUNT(*) FROM likes
UNION ALL SELECT 'subscriptions',COUNT(*) FROM subscriptions;
