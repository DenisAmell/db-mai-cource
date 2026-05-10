
CALL register_user('ivan_blogger', 'ivan@example.com');

DO $$
BEGIN
    CALL register_user('alice_writer', 'other@example.com');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;

DO $$
BEGIN
    CALL register_user('ghost_user', NULL);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;


CALL subscribe_to_blog(9, 2);

DO $$
BEGIN
    CALL subscribe_to_blog(3, 2);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;


DO $$
BEGIN
    CALL subscribe_to_blog(1, 1);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;


DO $$
BEGIN
    CALL subscribe_to_blog(1, 999);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;



DO $$
DECLARE
    v_id BIGINT;
BEGIN
    v_id := add_post(
        'Neural networks in 2024: trend overview',
        'Large language models have transformed the industry...',
        1, 2
    );
    RAISE NOTICE 'Post created with id=%', v_id;
END;
$$;


DO $$
BEGIN
    PERFORM add_post('Unauthorized post', 'Content', 1, 3);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;

DO $$
BEGIN
    PERFORM add_post('   ', 'Content', 1, 2);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;


SELECT * FROM get_user_stats(2);


SELECT * FROM get_user_stats(1);


DO $$
BEGIN
    PERFORM * FROM get_user_stats(999);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;



SELECT
    b.title                              AS blog_title,
    get_blog_popularity_score(b.id)      AS popularity_score
FROM blogs b
ORDER BY popularity_score DESC;


DO $$
BEGIN
    PERFORM get_blog_popularity_score(999);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[ERROR] %', SQLERRM;
END;
$$;



UPDATE posts
SET title = 'Git flow: best practices (revised)'
WHERE id = 7;

INSERT INTO posts (title, content, blog_id, author_id)
VALUES ('Audit test post', 'Trigger verification', 1, 2);


SELECT * FROM posts_audit ORDER BY changed_at DESC;

DO $$
BEGIN
    INSERT INTO subscriptions (subscriber_id, blog_id) VALUES (6, 4);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[TRIGGER] trg_prevent_self_subscription: %', SQLERRM;
END;
$$;


DO $$
BEGIN
    INSERT INTO posts (title, content, blog_id, author_id)
    VALUES ('', 'Content', 1, 2);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[TRIGGER] trg_validate_post: %', SQLERRM;
END;
$$;


DO $$
BEGIN
    INSERT INTO posts (title, content, blog_id, author_id)
    VALUES ('Valid title', 'Content', 1, 3);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '[TRIGGER] trg_validate_post: %', SQLERRM;
END;
$$;
