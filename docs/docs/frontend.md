---
id: frontend
title: Frontend
---

# Frontend

Frontend JobCompass реализован на Flutter Web.

## Где находится frontend

```text
jobcompass_ui
```

Основные директории:

- `lib/features` - экраны и UI по функциональным разделам.
- `lib/providers` - Riverpod providers.
- `lib/models` - модели данных.
- `lib/core/network` - API client.
- `lib/core/localization` - локализация.
- `test` - frontend-тесты.

## Локальный запуск

```bash
cd jobcompass_ui
flutter pub get
flutter run -d chrome --web-port 5124
```

## Настройка backend URL

По умолчанию frontend использует:

```text
http://localhost:8000
```

Для сборки с другим backend:

```bash
flutter build web \
  --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

## Сборка для GitHub Pages

GitHub Pages для project site обычно требует base href вида `/<repo>/`.

Пример:

```bash
flutter build web \
  --release \
  --base-href /career-pilot/ \
  --dart-define=API_BASE_URL=http://localhost:8000
```

В проекте это автоматизировано через GitHub Actions workflow.

## Локализация

Тексты находятся в:

```text
jobcompass_ui/lib/core/localization/app_localizations.dart
```

При добавлении нового текста нужно добавить ключ в русскую и английскую секции.
