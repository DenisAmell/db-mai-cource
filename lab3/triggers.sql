CREATE TABLE IF NOT EXISTS posts_audit (
    id         BIGSERIAL PRIMARY KEY,
    post_id    BIGINT       NOT NULL,
    operation  VARCHAR(10)  NOT NULL,
    old_title  VARCHAR(200),
    new_title  VARCHAR(200),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE FUNCTION fn_prevent_self_subscription()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_owner_id BIGINT;
BEGIN
    SELECT owner_id INTO v_owner_id
    FROM   blogs
    WHERE  id = NEW.blog_id;

    IF v_owner_id = NEW.subscriber_id THEN
        RAISE EXCEPTION
            'User id=% cannot subscribe to their own blog id=%',
            NEW.subscriber_id, NEW.blog_id
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_prevent_self_subscription
BEFORE INSERT ON subscriptions
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_self_subscription();


CREATE OR REPLACE FUNCTION fn_posts_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO posts_audit (post_id, operation, new_title)
        VALUES (NEW.id, 'INSERT', NEW.title);

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO posts_audit (post_id, operation, old_title, new_title)
        VALUES (NEW.id, 'UPDATE', OLD.title, NEW.title);

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO posts_audit (post_id, operation, old_title)
        VALUES (OLD.id, 'DELETE', OLD.title);
    END IF;

    RETURN NULL;  -- return value is ignored for AFTER triggers
END;
$$;

CREATE TRIGGER trg_posts_audit
AFTER INSERT OR UPDATE OR DELETE ON posts
FOR EACH ROW
EXECUTE FUNCTION fn_posts_audit();


CREATE OR REPLACE FUNCTION fn_validate_post()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_owner_id BIGINT;
BEGIN
    IF TRIM(NEW.title) = '' THEN
        RAISE EXCEPTION
            'Post title cannot be empty or consist of whitespace only'
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT owner_id INTO v_owner_id
    FROM   blogs
    WHERE  id = NEW.blog_id;

    IF v_owner_id <> NEW.author_id THEN
        RAISE EXCEPTION
            'User id=% is not the owner of blog id=%. Publishing is not allowed.',
            NEW.author_id, NEW.blog_id
            USING ERRCODE = 'insufficient_privilege';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validate_post
BEFORE INSERT OR UPDATE ON posts
FOR EACH ROW
EXECUTE FUNCTION fn_validate_post();
