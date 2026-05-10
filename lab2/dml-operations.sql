
INSERT INTO users (username, email)
VALUES ('henry_artist', 'henry@example.com');

INSERT INTO blogs (title, description, owner_id)
VALUES ('Арт-дневник', 'О современном искусстве и выставках', 8);

INSERT INTO posts (title, content, blog_id, author_id)
VALUES (
    'TypeScript: почему стоит перейти с JavaScript',
    'TypeScript добавляет статическую типизацию и делает крупные проекты значительно надёжнее.',
    4, 6
);

INSERT INTO subscriptions (subscriber_id, blog_id)
VALUES (8, 1);


UPDATE blogs
SET description = 'Технологии, AI и будущее цифрового мира'
WHERE id = 1;

UPDATE posts
SET title = 'Python vs JavaScript: сравнение в 2024 году'
WHERE id = 2;


UPDATE users
SET email = 'alice.writer@newmail.com'
WHERE username = 'alice_writer';


UPDATE posts
SET content = content || ' [Обновлено: добавлены примеры на Python 3.12]'
WHERE id = 1;


DELETE FROM likes
WHERE user_id = 1 AND post_id = 10;


DELETE FROM subscriptions
WHERE subscriber_id = 1 AND blog_id = 3;

DELETE FROM comments
WHERE id = 20;
