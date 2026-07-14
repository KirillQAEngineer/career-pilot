---
id: deployment
title: Deployment
---

# Deployment

На текущем этапе JobCompass публикует только статический frontend и документацию через GitHub Pages. Backend и база данных остаются локальными.

## Что публикуется

- Flutter Web приложение - корень GitHub Pages.
- Docusaurus документация - `/docs`.

Пример URL после публикации:

```text
https://kirillqaengineer.github.io/career-pilot/
https://kirillqaengineer.github.io/career-pilot/docs/
```

Фактический URL зависит от имени GitHub-репозитория.

## GitHub Actions

Workflow находится здесь:

```text
.github/workflows/github-pages.yml
```

Он выполняет:

1. Сборку Flutter Web.
2. Сборку Docusaurus.
3. Копирование Docusaurus build в `build/web/docs`.
4. Публикацию результата через GitHub Pages.

## Настройка GitHub Pages

В GitHub:

1. Открыть репозиторий.
2. Перейти в `Settings`.
3. Открыть `Pages`.
4. В `Build and deployment` выбрать `GitHub Actions`.
5. Запушить изменения в `main`.
6. Открыть вкладку `Actions` и дождаться успешного workflow.

## Backend URL

Сейчас backend локальный:

```text
http://localhost:8000
```

GitHub Pages не может хостить FastAPI backend. Когда появится внешний backend, нужно добавить repository variable:

```text
API_BASE_URL=https://api.example.com
```

После этого GitHub Actions соберёт Flutter Web с внешним API.

## Ограничения текущего контура

- Публичная страница GitHub Pages доступна всем.
- Backend остаётся локальным.
- Если пользователь открывает GitHub Pages без локального backend, данные из API не загрузятся.
- Для полноценной публичной платформы позже нужен отдельный backend-хостинг и публичная PostgreSQL.
