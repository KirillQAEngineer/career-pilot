---
id: deployment
title: Deployment
---

# Deployment

Production-публикация Flutter Web выполняется только после успешного check `CI Passed` для commit в `main`. Полная последовательность jobs описана в разделе [CI/CD и практика автотестов](./ci-cd.md).

JobCompass публикуется в три части:

- GitHub Pages - статический Flutter Web frontend и Docusaurus документация.
- Render - публичный FastAPI backend.
- Supabase - публичная PostgreSQL база данных.

## Что публикуется

- Flutter Web приложение - корень GitHub Pages.
- Docusaurus документация - `/docs`.

Пример URL после публикации:

```text
https://kirillqaengineer.github.io/JobCompass/
https://kirillqaengineer.github.io/JobCompass/docs/
```

Фактический URL зависит от имени GitHub-репозитория.

## GitHub Actions

Workflow находится здесь:

```text
.github/workflows/ci-cd.yml
```

Он выполняет:

1. Проверку backend, миграций и API на временной PostgreSQL.
2. Flutter format, analyze, autotests и production Web build.
3. Проверку и сборку Docusaurus.
4. Сборку Docker image backend.
5. Публикацию проверенных Flutter и Docusaurus artifacts через GitHub Pages только для `main`.

## Настройка GitHub Pages

В GitHub:

1. Открыть репозиторий.
2. Перейти в `Settings`.
3. Открыть `Pages`.
4. В `Build and deployment` выбрать `GitHub Actions`.
5. Запушить изменения в `main`.
6. Открыть вкладку `Actions` и дождаться успешного workflow.

## Backend URL

Локальный backend:

```text
http://localhost:8000
```

Публичный backend после деплоя на Render будет иметь адрес вида:

```text
https://jobcompass-api.onrender.com
```

GitHub Pages не может хостить FastAPI backend, поэтому после создания Render-сервиса нужно добавить GitHub repository variable:

```text
API_BASE_URL=https://jobcompass-api.onrender.com
```

После этого GitHub Actions соберёт Flutter Web с внешним API.

## Backend deploy через Render

В репозитории есть Blueprint:

```text
render.yaml
```

Он описывает Docker Web Service `jobcompass-api`, запускает миграции Alembic и стартует FastAPI:

```bash
alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

Порядок настройки:

1. Создать аккаунт Render.
2. Выбрать `New` -> `Blueprint`.
3. Подключить GitHub-репозиторий.
4. Выбрать ветку `main`.
5. Указать обязательные env variables:
   - `DATABASE_URL`
   - `SECRET_KEY`
   - `BACKEND_CORS_ORIGINS`
6. Добавить ключи внешних сервисов, если они используются:
   - `GEMINI_API_KEY`
   - `ADZUNA_APP_ID`
   - `ADZUNA_APP_KEY`
   - `JOOBLE_API_KEY`
7. Запустить deploy.
8. Проверить публичный endpoint:

```bash
curl https://jobcompass-api.onrender.com/
```

## PostgreSQL deploy через Supabase

Порядок настройки:

1. Создать аккаунт Supabase.
2. Создать новый проект.
3. Открыть `Project Settings` -> `Database`.
4. Скопировать connection string для PostgreSQL.
5. В Render добавить этот connection string в `DATABASE_URL`.
6. Убедиться, что URL начинается с драйвера SQLAlchemy:

```text
postgresql+psycopg://...
```

Если Supabase выдаёт строку вида `postgresql://...`, нужно заменить начало на `postgresql+psycopg://...`.

## CORS для публичного frontend

Backend читает разрешённые origins из переменной:

```text
BACKEND_CORS_ORIGINS=https://kirillqaengineer.github.io
```

Для локальной разработки можно использовать:

```text
BACKEND_CORS_ORIGINS=http://localhost,http://127.0.0.1,https://kirillqaengineer.github.io
```

## Ограничения бесплатного контура

- GitHub Pages хорошо подходит для frontend и документации.
- Render free web service может засыпать после простоя, поэтому первый запрос иногда будет медленнее.
- Supabase free project может быть paused после периода неактивности.
- Для стабильного production later лучше перейти на платные минимальные тарифы backend и DB.
