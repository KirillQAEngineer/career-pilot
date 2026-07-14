---
id: logging
title: Logging
---

# Logging

Сейчас базовые логи backend доступны через Docker stdout. Следующий технический этап - структурированное логирование.

## Где смотреть логи сейчас

Все backend-логи:

```bash
docker compose logs -f api
```

Последние 200 строк:

```bash
docker compose logs --tail=200 api
```

Логи базы:

```bash
docker compose logs -f postgres
```

## Что нужно логировать

Минимальный набор для production-ready backend:

- Входящий HTTP request.
- HTTP method и path.
- Status code.
- Время выполнения запроса.
- User ID, если пользователь авторизован.
- Request ID для связи событий.
- Ошибки с traceback.
- Ошибки внешних job providers.
- Количество вакансий, полученных от каждого источника.
- Количество вакансий после дедупликации и фильтрации.

## Рекомендуемый формат

Для backend лучше использовать JSON logs:

```json
{
  "level": "INFO",
  "event": "http_request",
  "method": "GET",
  "path": "/jobs/feed",
  "status_code": 200,
  "duration_ms": 184,
  "user_id": 1,
  "request_id": "..."
}
```

JSON проще читать в Render, Docker, Grafana, Loki, Datadog или любом будущем log storage.

## Рекомендуемый следующий этап

1. Добавить middleware для request logs.
2. Добавить request ID.
3. Перевести логи job providers на единый формат.
4. Добавить exception handler для traceback.
5. Документировать типовые ошибки и где их искать.
