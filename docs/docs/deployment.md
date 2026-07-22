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
   - `BREVO_API_KEY`
   - `EMAIL_FROM_ADDRESS`
   - `NOWPAYMENTS_API_KEY`
   - `NOWPAYMENTS_IPN_SECRET`
7. Запустить deploy.
8. Проверить публичный endpoint:

```bash
curl https://jobcompass-api.onrender.com/
```

Для ссылок из писем и возврата после оплаты также должны быть заданы:

```text
PUBLIC_API_BASE_URL=https://jobcompass-api.onrender.com
FRONTEND_BASE_URL=https://kirillqaengineer.github.io/JobCompass
EMAIL_DELIVERY_PROVIDER=brevo
EMAIL_FROM_NAME=JobCompass
ANALYTICS_LIFETIME_PRICE_MINOR_UNITS=100
ANALYTICS_LIFETIME_PRICE_CURRENCY=USD
ANALYTICS_LIFETIME_DISPLAY_PRICE=from 1 USDT
```

Секреты вводятся только в Render Environment. Их нельзя отправлять в чат,
добавлять в `.env.example`, workflow или коммитить в Git.

## Подтверждение почты через Brevo

1. Создать аккаунт Brevo и подтвердить отправителя в разделе Senders.
2. Создать API key для transactional email.
3. В Render записать ключ в `BREVO_API_KEY`, а подтверждённый адрес — в
   `EMAIL_FROM_ADDRESS`.
4. Выполнить deploy и зарегистрировать тестового пользователя.
5. Проверить получение письма, переход по ссылке и вход после подтверждения.

Новые аккаунты не получают JWT до подтверждения почты. Пользователи, созданные
до миграции, сохраняют возможность входа и могут подтвердить адрес из Профиля.

## Оплата Аналитики криптовалютой через NOWPayments

1. Зарегистрировать individual-аккаунт NOWPayments по email.
2. В кабинете добавить payout wallet USDT в сети Tron (TRC20). Проверить сеть
   особенно внимательно: адрес другой сети использовать нельзя. Адрес кошелька
   хранится у провайдера, а не в JobCompass.
3. В Coins Settings включить `USDTTRC20`, затем создать API key и IPN secret.
4. В Render Environment добавить только серверные секреты:

```text
NOWPAYMENTS_API_KEY=...
NOWPAYMENTS_IPN_SECRET=...
NOWPAYMENTS_PAY_CURRENCY=usdttrc20
```

5. Проверить публичные адреса, которые backend передаёт при создании счёта:

```text
PUBLIC_API_BASE_URL=https://jobcompass-api.onrender.com
FRONTEND_BASE_URL=https://kirillqaengineer.github.io/JobCompass
```

IPN callback формируется автоматически:
`https://jobcompass-api.onrender.com/billing/nowpayments/ipn`.

6. Выполнить deploy, войти подтверждённым аккаунтом и создать счёт из раздела
   Аналитика. После оплаты доступ активируется автоматически через IPN webhook;
   открытый экран также синхронизирует статус в фоне.
7. Проверить повторный вход: бессрочное право должно сохраниться в PostgreSQL.

Во всех языках пользователь может выбрать любую сумму от 1 USDT. Hosted invoice
NOWPayments принимает её как эквивалент в USD и рассчитывает итоговый
`pay_amount` в USDT TRC20; он может немного отличаться из-за курса и сетевой
комиссии. Нижний предел задаётся через
`ANALYTICS_LIFETIME_PRICE_MINOR_UNITS` без изменения кода.

Backend не получает seed-фразу или приватные ключи кошелька. Подписанный IPN
сам по себе не выдаёт доступ: JobCompass повторно запрашивает транзакцию у
NOWPayments и проверяет invoice ID, payment ID, order ID, валюту, точную сумму и
финальный статус `finished`. Запросы с неверной подписью отклоняются.

Обычная individual-регистрация не равна гарантии полного отсутствия проверок:
провайдер оставляет за собой право запросить KYC/AML-проверку подозрительной
транзакции. Если нужен полностью автономный приём без посредника, отдельным
этапом следует разворачивать self-hosted BTCPay Server.

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
