CREATE OR REPLACE PROCEDURE register_user(
    p_username VARCHAR,
    p_email    VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO users (username, email)
    VALUES (p_username, p_email);

    RAISE NOTICE 'User "%" registered successfully', p_username;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION
            'User with username "%" or email "%" already exists',
            p_username, p_email
            USING ERRCODE = 'unique_violation';
    WHEN not_null_violation THEN
        RAISE EXCEPTION
            'Username and email are required'
            USING ERRCODE = 'not_null_violation';
END;
$$;


CREATE OR REPLACE PROCEDURE subscribe_to_blog(
    p_subscriber_id BIGINT,
    p_blog_id       BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_owner_id   BIGINT;
    v_blog_title VARCHAR;
BEGIN
    SELECT owner_id, title
    INTO   v_owner_id, v_blog_title
    FROM   blogs
    WHERE  id = p_blog_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Blog with id=% does not exist', p_blog_id;
    END IF;

    IF v_owner_id = p_subscriber_id THEN
        RAISE EXCEPTION
            'Cannot subscribe to your own blog "%"', v_blog_title
            USING ERRCODE = 'check_violation';
    END IF;

    INSERT INTO subscriptions (subscriber_id, blog_id)
    VALUES (p_subscriber_id, p_blog_id);

    RAISE NOTICE 'User id=% subscribed to blog "%"',
        p_subscriber_id, v_blog_title;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION
            'User id=% is already subscribed to blog "%"',
            p_subscriber_id, v_blog_title
            USING ERRCODE = 'unique_violation';
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION
            'User id=% does not exist', p_subscriber_id
            USING ERRCODE = 'foreign_key_violation';
END;
$$;


CREATE OR REPLACE FUNCTION add_post(
    p_title     VARCHAR,
    p_content   TEXT,
    p_blog_id   BIGINT,
    p_author_id BIGINT
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_owner_id BIGINT;
    v_post_id  BIGINT;
BEGIN
    SELECT owner_id INTO v_owner_id
    FROM   blogs
    WHERE  id = p_blog_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Blog with id=% not found', p_blog_id;
    END IF;

    IF v_owner_id <> p_author_id THEN
        RAISE EXCEPTION
            'User id=% is not the owner of blog id=%. Publishing is not allowed.',
            p_author_id, p_blog_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    IF TRIM(p_title) = '' THEN
        RAISE EXCEPTION 'Post title cannot be empty'
            USING ERRCODE = 'check_violation';
    END IF;

    INSERT INTO posts (title, content, blog_id, author_id)
    VALUES (p_title, p_content, p_blog_id, p_author_id)
    RETURNING id INTO v_post_id;

    RAISE NOTICE 'Post "%" published (id=%)', p_title, v_post_id;
    RETURN v_post_id;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION
            'Blog id=% or user id=% does not exist',
            p_blog_id, p_author_id;
END;
$$;



CREATE OR REPLACE FUNCTION get_user_stats(p_user_id BIGINT)
RETURNS TABLE(
    username            VARCHAR,
    blogs_count         BIGINT,
    posts_count         BIGINT,
    comments_count      BIGINT,
    likes_given         BIGINT,
    subscriptions_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'User with id=% not found', p_user_id;
    END IF;

    RETURN QUERY
    SELECT
        u.username,
        COUNT(DISTINCT b.id)  AS blogs_count,
        COUNT(DISTINCT p.id)  AS posts_count,
        COUNT(DISTINCT c.id)  AS comments_count,
        COUNT(DISTINCT l.id)  AS likes_given,
        COUNT(DISTINCT s.id)  AS subscriptions_count
    FROM  users u
    LEFT JOIN blogs         b ON u.id = b.owner_id
    LEFT JOIN posts         p ON u.id = p.author_id
    LEFT JOIN comments      c ON u.id = c.user_id
    LEFT JOIN likes         l ON u.id = l.user_id
    LEFT JOIN subscriptions s ON u.id = s.subscriber_id
    WHERE u.id = p_user_id
    GROUP BY u.username;
END;
$$;


CREATE OR REPLACE FUNCTION get_blog_popularity_score(p_blog_id BIGINT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_posts       INT;
    v_subscribers INT;
    v_likes       INT;
    v_comments    INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM blogs WHERE id = p_blog_id) THEN
        RAISE EXCEPTION 'Blog with id=% not found', p_blog_id;
    END IF;

    SELECT COUNT(*) INTO v_posts
    FROM   posts WHERE blog_id = p_blog_id;

    SELECT COUNT(*) INTO v_subscribers
    FROM   subscriptions WHERE blog_id = p_blog_id;

    SELECT COUNT(l.id) INTO v_likes
    FROM   posts p
    JOIN   likes l ON p.id = l.post_id
    WHERE  p.blog_id = p_blog_id;

    SELECT COUNT(c.id) INTO v_comments
    FROM   posts p
    JOIN   comments c ON p.id = c.post_id
    WHERE  p.blog_id = p_blog_id;

    RETURN v_posts * 1 + v_subscribers * 3 + v_likes * 2 + v_comments * 1;
END;
$$;
