---
id: test-data
title: Test Data
---

# Test Data

Тестовые данные нужны для локальной проверки продукта. Не используйте реальные персональные данные в демонстрационных сценариях.

## Тестовый пользователь

Рекомендуемый локальный пользователь:

```text
email: qa@example.com
password: password123
```

Если регистрация или seed-скрипт ещё не автоматизированы, пользователя можно создать через UI или backend endpoint авторизации.

## Тестовое резюме

Минимальный профиль для проверки QA-вакансий:

```text
QA Engineer with 4 years of experience in manual and automated testing.
Skills: API testing, regression testing, test cases, bug reports, SQL.
Technologies: Postman, Docker, PostgreSQL, Git, Playwright, Selenium.
English: B2.
Preferred roles: QA Engineer, Test Engineer, SDET.
```

## Тестовые сценарии вакансий

### Хорошее совпадение

```text
Title: Senior QA Engineer
Company: Acme QA
Location: Remote
Description: API testing, regression testing, SQL, Postman, Docker.
```

Ожидаемо: высокий процент совпадения.

### Среднее совпадение

```text
Title: Manual QA Engineer
Company: Example Labs
Location: Hybrid
Description: Test cases, bug reports, mobile testing.
```

Ожидаемо: средний процент совпадения.

### Низкое совпадение

```text
Title: Sales Manager
Company: Example Sales
Location: Remote
Description: Cold calls, CRM sales pipeline, lead generation.
```

Ожидаемо: низкий процент совпадения или фильтрация из ленты.

## Тестовый комментарий

```text
Связаться с рекрутером в пятницу. Проверить стек автоматизации и формат интервью.
```

Комментарий должен быть виден в Feed, Saved, CRM и деталях одной и той же вакансии.
