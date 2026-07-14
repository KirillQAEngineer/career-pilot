---
id: local-development
title: Локальная разработка
---

# Локальная разработка

Эта инструкция описывает обычный рабочий цикл на локальном ПК.

## Запуск backend и базы

Из корня проекта:

```bash
docker compose up -d
```

Проверить контейнеры:

```bash
docker compose ps
```

Проверить backend:

```bash
curl http://localhost:8000/health
```

## Запуск frontend

Из корня проекта:

```bash
cd jobcompass_ui
flutter pub get
flutter run -d chrome --web-port 5124
```

Frontend по умолчанию обращается к backend по адресу:

```text
http://localhost:8000
```

Для другого backend-адреса при сборке или запуске можно использовать:

```bash
flutter run -d chrome --web-port 5124 \
  --dart-define=API_BASE_URL=http://localhost:8000
```

## Остановка окружения

```bash
docker compose down
```

Если нужно удалить локальные данные базы, сначала убедитесь, что данные больше не нужны.
