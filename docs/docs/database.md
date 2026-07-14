---
id: database
title: Database
---

# Database

JobCompass использует PostgreSQL. Схема базы управляется миграциями Alembic.

Локально база запускается через Docker Compose. Для публичного MVP-контура можно использовать Supabase PostgreSQL и передать connection string в backend через `DATABASE_URL`.

## Локальный запуск БД

```bash
docker compose up -d postgres
```

Проверка:

```bash
docker compose ps
```

## Применение миграций

```bash
docker compose exec api alembic upgrade head
```

Проверить текущую миграцию:

```bash
docker compose exec api alembic current
```

Показать историю миграций:

```bash
docker compose exec api alembic history
```

## Подключение к PostgreSQL

Через контейнер:

```bash
docker compose exec postgres psql -U postgres
```

Если база называется `jobcompass`, подключение:

```bash
docker compose exec postgres psql -U postgres -d jobcompass
```

Полезные команды psql:

```sql
\l
\dt
\d users
SELECT id, email, created_at FROM users ORDER BY id DESC LIMIT 10;
```

## Основные таблицы

- `users` - пользователи.
- `resume_profiles` - распарсенные резюме и профиль кандидата.
- `job_interactions` - сохранённые, скрытые и открытые вакансии.
- `applications` - CRM-отклики.
- `application_analytics_adjustments` - ручные корректировки Analytics.
- `job_comments` - комментарии к вакансиям.

## Создание новой миграции

После изменения SQLAlchemy моделей:

```bash
docker compose exec api alembic revision --autogenerate -m "short_description"
```

Проверить сгенерированный файл в `apps/api/alembic/versions`.

Применить:

```bash
docker compose exec api alembic upgrade head
```

## Откат миграции

Откатить одну миграцию:

```bash
docker compose exec api alembic downgrade -1
```

Использовать осторожно. Перед откатом на данных, которые важны, нужно сделать backup.

## Backup локальной базы

```bash
docker compose exec postgres pg_dump -U postgres jobcompass > backup.sql
```

Восстановление:

```bash
docker compose exec -T postgres psql -U postgres -d jobcompass < backup.sql
```

## Правила работы с БД

- Не менять структуру таблиц вручную без миграции.
- Не коммитить реальные дампы с персональными данными.
- Любое изменение модели должно иметь миграцию и тест.
- Перед сложными миграциями проверять сценарий rollback.

## Supabase для публичного контура

Для публичного backend нужна база, доступная из интернета. Базовый порядок:

1. Создать проект в Supabase.
2. Скопировать PostgreSQL connection string.
3. В Render добавить env variable `DATABASE_URL`.
4. Если строка начинается с `postgresql://`, заменить начало на:

```text
postgresql+psycopg://
```

5. После deploy Render выполнит:

```bash
alembic upgrade head
```

и создаст актуальную схему таблиц.

Важно: бесплатная база подходит для разработки и MVP, но не для гарантированного production SLA.
