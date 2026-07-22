# JobCompass

[![JobCompass CI/CD](https://github.com/KirillQAEngineer/JobCompass/actions/workflows/ci-cd.yml/badge.svg?branch=develop)](https://github.com/KirillQAEngineer/JobCompass/actions/workflows/ci-cd.yml)

AI-платформа для автоматизации поиска работы.

## Цель

JobCompass помогает специалистам:

- находить лучшие вакансии;
- оценивать соответствие требованиям;
- автоматически адаптировать резюме;
- генерировать сопроводительные письма;
- готовиться к интервью.

---

## Статус

🚧 Проект находится в активной разработке.

## Публичный контур

- Frontend и документация: GitHub Pages.
- Backend: Render Web Service.
- База данных: Supabase PostgreSQL.

Основные инструкции находятся в `docs/docs/deployment.md`.

Учебный CI/CD-контур и практика написания автотестов описаны в `docs/docs/ci-cd.md`.



------------------------------------------------------

Шпаргалка:

make up         # Запустить проект
make down       # Остановить проект
make logs       # Посмотреть логи
make api        # Запустить только API
make web        # Запустить только Frontend
make test       # Запустить тесты
make lint       # Проверка кода
