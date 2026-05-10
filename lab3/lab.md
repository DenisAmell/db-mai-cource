# Лабораторная работа №3


**Вариант 7: Блог-платформа с подписками**

## 1. База данных

Используемые таблицы: `users`, `blogs`, `posts`, `comments`, `likes`, `subscriptions`.

Дополнительная таблица, создаваемая в этой работе:

```sql
CREATE TABLE IF NOT EXISTS posts_audit (
    id         BIGSERIAL PRIMARY KEY,
    post_id    BIGINT      NOT NULL,
    operation  VARCHAR(10) NOT NULL,
    old_title  VARCHAR(200),
    new_title  VARCHAR(200),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```


## 2. Процедуры и функции

Скрипт: [`procedures.sql`](procedures.sql)

### Процедура `register_user`

Регистрирует нового пользователя. Перехватывает `unique_violation` (дублирование имени или email) и `not_null_violation`.

```sql
CALL register_user('ivan_blogger', 'ivan@example.com');
```

### Процедура `subscribe_to_blog`

Подписывает пользователя на блог. Проверяет: блог существует, нет самоподписки, нет повторной подписки. Перехватывает `unique_violation` и `foreign_key_violation`.

```sql
CALL subscribe_to_blog(9, 2);  -- ivan_blogger подписывается на «Кулинарные истории»
```

### Функция `add_post`

Публикует пост от имени владельца блога. Проверяет права автора и непустой заголовок. Возвращает `id` созданного поста.

```sql
SELECT add_post('Нейросети в 2024', 'Текст...', 1, 2);
```

### Функция `get_user_stats`

Возвращает сводную статистику пользователя: число блогов, постов, комментариев, лайков и подписок.

```sql
SELECT * FROM get_user_stats(2);
```

| username | blogs_count | posts_count | comments_count | likes_given | subscriptions_count |
|:---|:---:|:---:|:---:|:---:|:---:|
| bob_techie | 1 | 4 | 1 | 3 | 2 |

### Функция `get_blog_popularity_score`

Вычисляет числовой рейтинг блога по формуле: `посты×1 + подписчики×3 + лайки×2 + комментарии×1`.

```sql
SELECT b.title, get_blog_popularity_score(b.id) AS score
FROM blogs b
ORDER BY score DESC;
```

## 3. Триггеры

Скрипт: [`triggers.sql`](triggers.sql)

### Триггер `trg_prevent_self_subscription`

**Тип:** `BEFORE INSERT` на `subscriptions`  
**Задача:** блокирует подписку владельца на собственный блог.

```sql
INSERT INTO subscriptions (subscriber_id, blog_id) VALUES (6, 4);
```

### Триггер `trg_posts_audit`

**Тип:** `AFTER INSERT OR UPDATE OR DELETE` на `posts`  
**Задача:** записывает каждое изменение поста в таблицу `posts_audit` — создание, редактирование заголовка, удаление.

```sql
UPDATE posts SET title = 'Git flow (обновлено)' WHERE id = 7;
SELECT * FROM posts_audit ORDER BY changed_at DESC;
```

| post_id | operation | old_title | new_title | changed_at |
|:---:|:---:|:---|:---|:---|
| 7 | UPDATE | Git flow: лучшие практики | Git flow (обновлено) | 2024-05-01 10:00:00 |

### Триггер `trg_validate_post`

**Тип:** `BEFORE INSERT OR UPDATE` на `posts`  
**Задача:** проверяет два правила:
1. Заголовок не пустой и не состоит из пробелов.
2. Автор является владельцем блога.

```sql
INSERT INTO posts (title, content, blog_id, author_id) VALUES ('', 'Текст', 1, 2);

INSERT INTO posts (title, content, blog_id, author_id) VALUES ('Заголовок', 'Текст', 1, 3);
```

---

## 4. Обработка ошибок

В процедурах и функциях используется блок `EXCEPTION`

| Системная ошибка | Бизнес-сообщение |
|:---|:---|
| `unique_violation` | «Пользователь с таким именем или email уже зарегистрирован» |
| `unique_violation` | «Пользователь уже подписан на этот блог» |
| `foreign_key_violation` | «Пользователь или блог не существует» |
| `not_null_violation` | «Имя пользователя и email обязательны» |
| `insufficient_privilege` | «Публикация в чужом блоге запрещена» |
| `check_violation` | «Заголовок поста не может быть пустым» |

Триггеры используют `RAISE EXCEPTION` с явным `ERRCODE`


## 5. Примеры использования

Скрипт: [`usage-examples.sql`](usage-examples.sql)
