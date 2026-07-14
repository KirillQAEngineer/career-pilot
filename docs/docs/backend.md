---
id: backend
title: Backend
---

# Backend

Backend JobCompass реализован на FastAPI. Он отвечает за пользователей, загрузку резюме, профиль, вакансии, сохранённые вакансии, CRM, комментарии, аналитику и генерацию сопроводительных писем.

## Где находится backend

```text
apps/api
```

Основные директории:

- `app/api/routes` - HTTP routes.
- `app/db/models` - SQLAlchemy модели.
- `app/db/repositories` - работа с БД.
- `app/schemas` - Pydantic схемы.
- `app/services` - бизнес-логика.
- `alembic/versions` - миграции базы данных.
- `tests` - backend-тесты.

## Локальный запуск

Backend запускается через Docker Compose:

```bash
docker compose up -d api
```

Проверка:

```bash
curl http://localhost:8000/health
```

## Основные команды

Запустить тесты backend:

```bash
docker compose exec -e PYTHONPATH=/app api pytest
```

Запустить отдельный тестовый файл:

```bash
docker compose exec -e PYTHONPATH=/app api pytest tests/services/jobs/test_rss_provider.py
```

Применить миграции:

```bash
docker compose exec api alembic upgrade head
```

Создать новую миграцию:

```bash
docker compose exec api alembic revision -m "describe_change"
```

## Переменные окружения

Переменные окружения задаются через `.env` или Docker Compose. В репозиторий нельзя коммитить реальные секреты.

Типовые переменные:

- `DATABASE_URL` - подключение к PostgreSQL.
- `JWT_SECRET_KEY` - ключ подписи JWT.
- `ADZUNA_APP_ID` и `ADZUNA_APP_KEY` - ключи Adzuna.
- AI provider keys - ключи используемых AI-провайдеров.

## Как добавлять API endpoint

1. Добавить route в `app/api/routes`.
2. Добавить Pydantic schema в `app/schemas`, если нужны request/response модели.
3. Вынести работу с БД в repository.
4. Добавить бизнес-логику в service.
5. Покрыть тестами happy path и ошибки.
