# Лабораторная работа №4

**Вариант 7: Блог-платформа с подписками**

## Наполнение БД

Скрипт: [`mock-data.sql`](mock-data.sql)

Чтобы планировщик действительно выбирал индексные стратегии вместо `Seq Scan`, в таблицы заливаются моковые данные.


## 1. Индексы

Скрипт: [`indexes.sql`](indexes.sql)

Для каждого индекса в скрипте выполняется один и тот же запрос дважды — **до** и **после** создания индекса — с помощью `EXPLAIN ANALYZE`. Это позволяет увидеть переход от `Seq Scan` к `Index Scan` / `Bitmap Index Scan` и сравнить время выполнения.

| № | Индекс | Тип | Колонка | Назначение запроса |
|:-:|:---|:---:|:---|:---|
| 1 | `idx_posts_published_at_brin` | **BRIN** | `posts(published_at)` | Поиск по диапазону дат |
| 2a | `idx_users_email_hash` | **Hash** | `users(email)` | Точечный поиск по равенству |
| 2b | `idx_users_username` | **B-tree** | `users(username)` | Сортировка по тексту |
| 3 | `idx_posts_title_trgm` | **GIN** (`pg_trgm`) | `posts(title)` | Поиск по подстроке `ILIKE '%...%'` |
| 4 | `idx_posts_blog_published` | **B-tree** составной | `posts(blog_id, published_at)` | Фильтр по блогу + сортировка по дате |
| 5 | `idx_comments_post_id`, `idx_likes_post_id` | **B-tree** | FK на `posts(id)` | Ускорение JOIN |

Используются **четыре разных типа индексов** — каждый под свой класс операций:

* **B-tree** — универсальный, поддерживает `=`, `<`, `>`, `BETWEEN`, `ORDER BY`, префиксный `LIKE 'x%'`. Лучший выбор по умолчанию.
* **Hash** — только `=`. Компактнее B-tree, быстрее для точечных запросов, но не умеет сортировку и диапазоны.
* **BRIN** (Block Range INdex) — хранит min/max значения по блокам страниц. Очень компактный, эффективен для больших таблиц с естественной упорядоченностью данных (например, временные ряды).
* **GIN** с `pg_trgm` — для поиска по подстроке. Единственный индекс, который ускоряет `LIKE '%...%'` и `ILIKE '%...%'`.

### Сравнение планов выполнения

| Запрос | До индекса | Время выполнения до | После индекса | Время выполнения после 
|:---|:---|:---|:---|:---|
| Диапазон по `published_at` | `Seq Scan` + `Filter` | Planning Time: 0.195 ms <br> Execution Time: 14.516 ms | `Index Scan` по `idx_posts_published_at` |  Planning Time: 0.308 ms <br> Execution Time: 4.269 ms |
| Точный поиск `username` | `Seq Scan` + `Filter`| Planning Time: 0.190 ms <br> Execution Time: 0.870 ms | `Index Scan` по `idx_users_username` | Planning Time: 0.135 ms Execution Time: 0.023 ms |
| `ILIKE '%Docker%'`         | `Seq Scan` + `Filter` | Planning Time: 0.840 ms <br> Execution Time: 51.860 ms | `Bitmap Index Scan` по GIN-индексу | Planning Time: 0.181 ms <br> Execution Time: 7.771 ms |
| Фильтр блога + сортировка  | `Seq Scan` + `Sort` | Planning Time: 0.111 ms<br>Execution Time: 8.834 ms | `Index Scan` по составному индексу (без `Sort`) | Planning Time: 0.464 ms <br> Execution Time: 0.161 ms |
| JOIN `posts ↔ comments/likes` | `Hash Join` на полной выборке | Planning Time: 0.896 ms <br> Execution Time: 388.479 ms | `Nested Loop` с `Index Scan` по FK | Planning Time: 0.231 ms <br> Execution Time: 370.437 ms |

## 2. Анализ производительности с EXPLAIN

Скрипт: [`explain-queries.sql`](explain-queries.sql)

| № | Запрос | Ожидаемое до индексов | Ожидаемое после индексов |
|:-:|:---|:---|:---|
| 1 | Топ-5 постов с автором и блогом за период | `Seq Scan` + `Hash Join` + `Sort`     | `Index Scan` по `published_at` + `Nested Loop` |
| 2 | Активность пользователей по всем сущностям| Множественные `Hash Join`             | `Hash Join` + `Index Scan` по FK   |
| 3 | Поиск постов блога по подстроке           | `Seq Scan` + двойной `Filter`         | `Bitmap And` (`blog_id` + GIN)      |
| 4 | Лента подписчика                          | `Hash Join` + `Sort`                  | `Nested Loop` + `Index Scan`        |
| 5 | Сводный рейтинг блогов                    | `Hash Join` + `HashAggregate`         | `Index Scan` по FK + `HashAggregate`|

### Вывод

Индексы радикально меняют стратегию планировщика: на маленьких таблицах разница в миллисекундах, но уже на нескольких сотнях тысяч строк `Seq Scan` обходится в десятки раз дороже `Index Scan`. Составной индекс `(blog_id, published_at)` устраняет операцию `Sort`, что даёт особенно заметный выигрыш в запросах с `ORDER BY ... LIMIT`. GIN-индекс на триграммах — лучший способ ускорить `ILIKE '%...%'`, потому что обычный B-tree для поиска по подстроке не работает.

## 3. Транзакции и аномалии параллельного доступа

Скрипт: [`transactions.sql`](transactions.sql)

Все сценарии запускаются в **двух параллельных сессиях** `psql` — `T1` и `T2`.

### Сценарий 1 — Dirty read

| Шаг | T1 | T2 |
|:-:|:---|:---|
| 1 | `BEGIN; SET ISOLATION LEVEL READ UNCOMMITTED;` | |
| 2 | `UPDATE post_stats SET likes_cnt = 999 WHERE post_id = 1;` (без COMMIT) | |
| 3 | | `BEGIN; SELECT likes_cnt FROM post_stats WHERE post_id = 1;` |
| 4 | | Результат: **0** (старое значение) |
| 5 | `ROLLBACK;` | |

**Аномалия отсутствует.** PostgreSQL не поддерживает реальный `READ UNCOMMITTED`: уровень молча повышается до `READ COMMITTED`. Это уже защищает от dirty read — менять изоляцию не нужно.

### Сценарий 2 — Non-repeatable read

| Шаг | T1 | T2 |
|:-:|:---|:---|
| 1 | `BEGIN; SET ISOLATION LEVEL READ COMMITTED;` | |
| 2 | `SELECT likes_cnt ... WHERE post_id = 1;` → **0** | |
| 3 | | `BEGIN; UPDATE ... SET likes_cnt = 42 WHERE post_id = 1; COMMIT;` |
| 4 | `SELECT likes_cnt ... WHERE post_id = 1;` → **42** | |
| 5 | `COMMIT;` | |

**Аномалия:** одинаковые `SELECT` внутри одной транзакции вернули разные значения.

**Лечение:** поднять уровень до `REPEATABLE READ` — T1 будет работать со снимком данных на момент `BEGIN`, и оба `SELECT` вернут одно и то же значение.

### Сценарий 3 — Phantom read

| Шаг | T1 | T2 |
|:-:|:---|:---|
| 1 | `BEGIN; SET ISOLATION LEVEL READ COMMITTED;` | |
| 2 | `SELECT COUNT(*) FROM posts WHERE blog_id = 1;` → **N** | |
| 3 | | `INSERT INTO posts (...) VALUES (..., 1, 2); COMMIT;` |
| 4 | `SELECT COUNT(*) FROM posts WHERE blog_id = 1;` → **N+1** | |
| 5 | `COMMIT;` | |

**Аномалия:** появилась новая (фантомная) строка, удовлетворяющая условию.

**Лечение:** `SERIALIZABLE`. PostgreSQL обнаружит конфликт чтения/записи и при коммите T1 выдаст ошибку `serialization_failure`. В таком случае транзакцию нужно повторить — данные останутся согласованными.

### Уровни изоляции в PostgreSQL

| Уровень | Dirty read | Non-repeatable read | Phantom read |
|:---|:-:|:-:|:-:|
| READ UNCOMMITTED | нет (== READ COMMITTED) | возможна | возможна |
| READ COMMITTED   | нет | возможна | возможна |
| REPEATABLE READ  | нет | нет      | нет (snapshot isolation) |
| SERIALIZABLE     | нет | нет      | нет |

В PostgreSQL `REPEATABLE READ` уже защищает от phantom read — это особенность реализации через snapshot isolation. `SERIALIZABLE` дополнительно ловит более сложные конфликты записи/чтения и при их обнаружении откатывает одну из транзакций.

## 4. Вывод

* Правильно подобранные индексы переводят запросы с последовательного сканирования (`Seq Scan`) на индексные стратегии (`Index Scan`, `Bitmap Index Scan`, `Nested Loop`), радикально ускоряя выборку.
* Команда `EXPLAIN ANALYZE` — основной инструмент для проверки того, что планировщик действительно использует созданный индекс.
* Аномалии параллельного доступа закрываются последовательно: PostgreSQL уже на минимальном уровне защищает от dirty read; non-repeatable read убирается переходом на `REPEATABLE READ`, phantom read — на `SERIALIZABLE`.
