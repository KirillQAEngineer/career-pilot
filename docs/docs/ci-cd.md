---
id: ci-cd
title: CI/CD и практика автотестов
---

# CI/CD и практика автотестов

В JobCompass настроен настоящий GitHub Actions pipeline. Он работает на бесплатных GitHub-hosted runners и запускается автоматически после создания или обновления Pull Request в `develop` или `main`.

Workflow находится в `.github/workflows/ci-cd.yml`.

## Схема работы

1. Разработчик создаёт отдельную ветку от `develop`.
2. Добавляет код и автотесты, делает commit и push.
3. Создаёт Pull Request в `develop`.
4. GitHub автоматически запускает backend, frontend и documentation jobs.
5. После их успешного завершения собирается Docker-образ backend.
6. Общий check `CI Passed` становится зелёным только после прохождения всех обязательных этапов.
7. Изменения объединяются с `develop`.
8. Когда готовый `develop` объединяется с `main`, pipeline запускается повторно и публикует проверенный Flutter Web вместе с документацией в GitHub Pages.

Публикация при Pull Request не выполняется. PR только проверяет код и создаёт временные build-артефакты.

## Этапы pipeline

| Job | Что проверяется | Результат |
| --- | --- | --- |
| Backend | Python dependencies, компиляция, Alembic, PostgreSQL, Pytest, API smoke | JUnit XML и API log |
| Frontend | Dart format, Flutter Analyze, Flutter tests, Web build | LCOV coverage и собранный сайт |
| Documentation | Чистая установка npm, audit critical, Docusaurus build | Собранная документация |
| Package | Сборка backend Docker image | Проверенный Docker-образ внутри runner |
| CI Passed | Результаты всех обязательных jobs | Общий зелёный или красный check |
| CD | Сборка Pages artifact и deploy | Выполняется только для успешного `main` |

Каждый job запускается в новом временном окружении. Backend получает отдельный PostgreSQL 17 service container, поэтому тесты не используют локальную или production-базу.

## Первый учебный Pull Request

Создайте ветку от актуального `develop`:

```bash
git switch develop
git pull
git switch -c test/my-first-autotest
```

Добавьте или измените тест, затем проверьте его локально:

```bash
make lint
make test
```

Отправьте ветку:

```bash
git add .
git commit -m "test: add my first autotest"
git push -u origin test/my-first-autotest
```

На GitHub создайте Pull Request: `test/my-first-autotest` → `develop`. Во вкладке **Checks** появятся отдельные jobs. Нажатие на job открывает последовательность шагов и полный log.

## Где писать backend-автотесты

Backend-тесты находятся в `apps/api/tests`:

- `api` — проверки HTTP endpoints, авторизации и кодов ответа;
- `db/repositories` — работа с базой и ограничениями;
- `schemas` — валидация Pydantic-схем;
- `services` — бизнес-логика, парсеры и внешние providers.

Минимальный тест:

```python
def test_total_is_sum_of_items():
    items = [2, 3, 5]

    assert sum(items) == 10
```

Запустить один файл:

```bash
PYTHONPATH=apps/api apps/api/.venv/bin/python -m pytest \
  apps/api/tests/path/to/test_file.py -v
```

Запустить один тест:

```bash
PYTHONPATH=apps/api apps/api/.venv/bin/python -m pytest \
  apps/api/tests/path/to/test_file.py::test_name -v
```

Для API-тестов используйте `TestClient`, отдельную тестовую БД или dependency override. Тест не должен обращаться к production Supabase и не должен зависеть от реального внешнего job provider.

## Где писать Flutter-автотесты

Flutter-тесты находятся в `jobcompass_ui/test`:

- `features` — widget- и service-тесты отдельных функций;
- `providers` — Riverpod state и API-сценарии;
- `widget_test.dart` — базовая проверка приложения.

Минимальный unit-тест:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes an email', () {
    final result = ' User@Example.com '.trim().toLowerCase();

    expect(result, 'user@example.com');
  });
}
```

Запустить один файл:

```bash
cd jobcompass_ui
flutter test test/path/to/file_test.dart
```

## Как потренировать падение pipeline

1. Создайте учебную ветку.
2. Добавьте тест с заведомо неправильным ожиданием, например `assert 2 + 2 == 5`.
3. Сделайте push и откройте PR в `develop`.
4. Откройте красный backend job и найдите в log имя упавшего теста, expected и actual result.
5. Исправьте ожидание на правильное.
6. Сделайте новый commit и push в ту же ветку.
7. GitHub отменит устаревший run, запустит новый и обновит check в существующем PR.

Не объединяйте намеренно сломанный тест с `develop`.

## Артефакты

Внизу страницы завершённого workflow можно скачать:

- `backend-test-reports-*` — JUnit-отчёт и log тестового API;
- `flutter-coverage-*` — Flutter coverage в формате LCOV;
- `web-app-*` — production build Flutter Web;
- `documentation-*` — production build Docusaurus.

Учебные артефакты хранятся 7 дней.

## Локальный эквивалент CI

Основные команды:

```bash
make lint
make test
make docs-build
make web-build
make docker-build
```

Полная локальная последовательность:

```bash
make ci
```

По умолчанию Makefile использует `apps/api/.venv/bin/python`. Другой Python можно передать явно:

```bash
make backend-test PYTHON=python3
```

## Branch protection

Чтобы нельзя было случайно объединить красный PR:

1. Откройте GitHub repository → **Settings** → **Branches** или **Rules**.
2. Создайте правило для `develop`, затем для `main`.
3. Включите **Require a pull request before merging**.
4. Включите **Require status checks to pass before merging**.
5. Выберите обязательный check `CI Passed`.
6. Для `main` дополнительно запретите прямой push.

Сначала дождитесь хотя бы одного завершённого pipeline: GitHub показывает check в списке только после его первого запуска.

## Что делать при ошибке

- `Backend` — найти первый traceback или failed test; проверить миграции и HTTP status.
- `Frontend` — проверить format, analyzer, затем конкретный Flutter test.
- `Documentation` — проверить npm install, broken link или ошибку MDX.
- `Package` — проверить Dockerfile и наличие файлов в build context.
- `CI Passed` — посмотреть, какой предыдущий job имеет `failure`, `cancelled` или `skipped`.

Кнопка **Re-run failed jobs** полезна только для временного сбоя runner. Ошибку в коде нужно исправлять новым commit.
