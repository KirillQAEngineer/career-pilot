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
- `PUBLIC_API_BASE_URL` - публичная база URL backend для ссылок подтверждения.
- `FRONTEND_BASE_URL` - адрес Flutter Web для возврата после подтверждения и оплаты.
- `EMAIL_DELIVERY_PROVIDER=brevo`, `BREVO_API_KEY`, `EMAIL_FROM_ADDRESS` -
  отправка transactional email.
- `NOWPAYMENTS_API_KEY` - серверный API key для создания криптосчетов.
- `NOWPAYMENTS_IPN_SECRET` - секрет проверки подписанных уведомлений об оплате.
- `ANALYTICS_LIFETIME_PRICE_MINOR_UNITS=125` и
  `ANALYTICS_LIFETIME_PRICE_CURRENCY=USD` - реальная сумма счёта: 1.25 USD.
- `ANALYTICS_LIFETIME_DISPLAY_PRICE=99 ₽` - рекламное отображение цены в UI.
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

## Подтверждение email

- `POST /auth/register` создаёт неподтверждённый аккаунт и отправляет письмо,
  но не выдаёт access token.
- `GET /auth/verify-email?token=...` принимает одноразовый ограниченный по
  времени токен. В БД хранится только SHA-256 hash токена.
- `POST /auth/resend-verification` не раскрывает существование аккаунта.
- `POST /auth/me/send-verification` позволяет старому авторизованному
  пользователю подтвердить адрес из Профиля.

## Платный доступ к Аналитике

- `GET /billing/me` возвращает право доступа и состояние последнего платежа.
- `POST /billing/analytics-lifetime/checkout` создаёт криптосчёт NOWPayments.
- `POST /billing/analytics-lifetime/refresh` безопасно перепроверяет платёж.
- `POST /billing/nowpayments/ipn` принимает уведомление, проверяет его
  HMAC-SHA512 подпись, а затем независимо читает платёж из API провайдера.
- Доступ выдаётся только после статуса `finished`, совпадения invoice ID,
  payment ID, order ID, валюты и точной суммы.
- Все `/applications/*` дополнительно защищены серверной проверкой бессрочного
  права. Администраторы имеют доступ без покупки.

## Кэш вакансий

Adzuna и Jooble читаются постранично, запросы к независимым источникам идут
параллельно с ограниченным таймаутом. Уникальные вакансии сохраняются в таблицу
`cached_jobs` на 14 дней. Это позволяет быстро отдать ранее найденные результаты,
если внешний источник временно недоступен, не создавая искусственных дублей.

Администратор не может снять права со своего текущего аккаунта. Это защищает платформу от случайной потери последнего доступного административного сеанса.

## Как добавлять API endpoint

1. Добавить route в `app/api/routes`.
2. Добавить Pydantic schema в `app/schemas`, если нужны request/response модели.
3. Вынести работу с БД в repository.
4. Добавить бизнес-логику в service.
5. Покрыть тестами happy path и ошибки.
