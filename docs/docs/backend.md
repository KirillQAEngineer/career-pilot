---
id: backend
title: Backend
---

# Backend

Backend JobCompass реализован на FastAPI. Он отвечает за пользователей и роли, ручной профиль и резюме, вакансии, сохранённые вакансии, отклики, комментарии, аналитику и генерацию документов.

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
- `DATABASE_URL_DOCKER` - локальное подключение к PostgreSQL внутри Docker Compose.
- `SECRET_KEY` - ключ подписи JWT.
- `BACKEND_CORS_ORIGINS` - список origins, которым разрешён доступ к API.
- `ADZUNA_APP_ID` и `ADZUNA_APP_KEY` - ключи Adzuna.
- `JOOBLE_API_KEY` - ключ Jooble.
- `GEMINI_API_KEY` - ключ Gemini.
- AI provider keys - ключи используемых AI-провайдеров.

## Публичный запуск

Для публичного доступа backend размещается отдельно от GitHub Pages. Рекомендуемый MVP-вариант:

- Render Web Service для FastAPI.
- Supabase PostgreSQL для базы данных.

Render использует файл:

```text
render.yaml
```

На старте сервиса выполняется:

```bash
alembic upgrade head
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

Это значит, что миграции применяются автоматически при деплое.

## Аккаунт, профиль и права доступа

- `GET /auth/me` возвращает ID, логин, имя, дату регистрации и роль текущего пользователя.
- `PUT /profile/me` создаёт или обновляет профиль без обязательной загрузки резюме.
- `DELETE /profile/me/resume` удаляет только текст загруженного резюме, сохраняя ручные поля профиля.
- `/admin/*` доступен только пользователям с `is_admin = true`; проверка выполняется на backend, а не только скрытием вкладки в UI.
- `GET /admin/stats` и `GET /admin/users` возвращают общую статистику и список аккаунтов.
- `GET /admin/users/{id}` возвращает карточку пользователя, а `PATCH /admin/users/{id}/role` меняет его роль.

Администратор не может снять права со своего текущего аккаунта. Это защищает платформу от случайной потери последнего доступного административного сеанса.

## Как добавлять API endpoint

1. Добавить route в `app/api/routes`.
2. Добавить Pydantic schema в `app/schemas`, если нужны request/response модели.
3. Вынести работу с БД в repository.
4. Добавить бизнес-логику в service.
5. Покрыть тестами happy path и ошибки.
