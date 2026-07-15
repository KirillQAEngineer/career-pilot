import re

from app.schemas.resume_profile import ResumeProfile


class ResumeProfileEnricher:
    """Adds deterministic resume facts that an AI response may omit."""

    SKILLS = (
        ("API Testing", ("api testing", "тестирование api", "тестирование апи")),
        ("REST API", ("rest api", "restful", "rest-api")),
        ("SOAP", ("soap api", "soap ui", "soapui")),
        ("GraphQL", ("graphql",)),
        (
            "Manual Testing",
            ("manual testing", "manual qa", "manual", "ручное тестирование"),
        ),
        ("Automation Testing", ("automation testing", "test automation", "автоматизация тестирования", "автотест")),
        (
            "Regression Testing",
            ("regression testing", "regression", "регрессионное тестирование", "регресс"),
        ),
        (
            "Smoke Testing",
            ("smoke testing", "smoke test", "smoke", "смоук", "дымовое тестирование"),
        ),
        (
            "Integration Testing",
            ("integration testing", "integration", "интеграционное тестирование"),
        ),
        ("System Testing", ("system testing", "системное тестирование")),
        ("End-to-End Testing", ("end-to-end", "end to end", "e2e")),
        ("Exploratory Testing", ("exploratory testing", "исследовательское тестирование")),
        ("Functional Testing", ("functional testing", "функциональное тестирование")),
        ("Non-functional Testing", ("non-functional testing", "нефункциональное тестирование")),
        ("Performance Testing", ("performance testing", "тестирование производительности")),
        ("Load Testing", ("load testing", "нагрузочное тестирование")),
        ("Security Testing", ("security testing", "тестирование безопасности")),
        ("Mobile Testing", ("mobile testing", "тестирование мобильных", "mobile qa")),
        ("Web Testing", ("web testing", "тестирование web", "тестирование веб")),
        ("UI Testing", ("ui testing", "gui testing", "тестирование интерфейса")),
        ("Backend Testing", ("backend testing", "back-end testing", "тестирование backend", "тестирование бэкенд")),
        ("Cross-browser Testing", ("cross-browser", "cross browser", "кроссбраузер")),
        ("Accessibility Testing", ("accessibility testing", "a11y", "тестирование доступности")),
        ("Usability Testing", ("usability testing", "тестирование юзабилити")),
        ("Test Design", ("test design", "тест-дизайн", "тест дизайн")),
        ("Test Cases", ("test case", "test cases", "тест-кейс", "тест кейс")),
        (
            "Checklists",
            ("checklist", "checklists", "check-list", "чек-лист", "чек лист"),
        ),
        ("Test Plans", ("test plan", "тест-план", "план тестирования")),
        ("Test Strategy", ("test strategy", "стратегия тестирования")),
        (
            "Requirements Analysis",
            ("requirements analysis", "analyzed requirements", "анализ требований"),
        ),
        ("Bug Reporting", ("bug reporting", "bug report", "баг-репорт", "баг репорт")),
        ("Defect Management", ("defect management", "управление дефектами")),
        ("Root Cause Analysis", ("root cause analysis", "rca", "анализ первопричин")),
        ("Risk Analysis", ("risk analysis", "анализ рисков")),
        ("SQL", ("sql", "sql queries", "sql запрос")),
        ("JSON", ("json",)),
        ("XML", ("xml",)),
        ("HTTP", ("http", "https")),
        ("Client-server Architecture", ("client-server", "client server", "клиент-сервер")),
        ("Microservices", ("microservice", "микросервис")),
        ("CI/CD", ("ci/cd", "continuous integration", "continuous delivery", "непрерывная интеграция")),
        ("Agile", ("agile", "гибкая методология")),
        ("Scrum", ("scrum",)),
        ("Kanban", ("kanban",)),
    )

    TECHNOLOGIES = (
        ("Postman", ("postman",)),
        ("Swagger", ("swagger", "openapi")),
        ("Selenium", ("selenium",)),
        ("Playwright", ("playwright",)),
        ("Cypress", ("cypress",)),
        ("Appium", ("appium",)),
        ("Pytest", ("pytest",)),
        ("JUnit", ("junit",)),
        ("TestNG", ("testng",)),
        ("REST Assured", ("rest assured", "rest-assured")),
        ("JMeter", ("jmeter",)),
        ("Gatling", ("gatling",)),
        ("Charles Proxy", ("charles proxy", "charles")),
        ("Fiddler", ("fiddler",)),
        ("Chrome DevTools", ("chrome devtools", "devtools")),
        ("Jira", ("jira",)),
        ("Confluence", ("confluence",)),
        ("TestRail", ("testrail",)),
        ("Qase", ("qase",)),
        ("Allure", ("allure",)),
        ("Jenkins", ("jenkins",)),
        ("GitHub Actions", ("github actions",)),
        ("GitLab CI", ("gitlab ci", "gitlab-ci")),
        ("TeamCity", ("teamcity",)),
        ("Docker", ("docker",)),
        ("Kubernetes", ("kubernetes", "k8s")),
        ("Git", ("git",)),
        ("Linux", ("linux",)),
        ("Bash", ("bash", "shell scripting")),
        ("Python", ("python",)),
        ("Java", ("java",)),
        ("JavaScript", ("javascript", "java script")),
        ("TypeScript", ("typescript", "type script")),
        ("C#", ("c#", "c sharp")),
        ("C++", ("c++",)),
        ("Kotlin", ("kotlin",)),
        ("Swift", ("swift",)),
        ("Dart", ("dart",)),
        ("Flutter", ("flutter",)),
        ("FastAPI", ("fastapi",)),
        ("Django", ("django",)),
        ("Spring", ("spring boot", "spring framework")),
        ("PostgreSQL", ("postgresql", "postgres")),
        ("MySQL", ("mysql",)),
        ("Microsoft SQL Server", ("mssql", "sql server")),
        ("MongoDB", ("mongodb", "mongo db")),
        ("Redis", ("redis",)),
        ("Kafka", ("kafka",)),
        ("RabbitMQ", ("rabbitmq", "rabbit mq")),
        ("Grafana", ("grafana",)),
        ("Kibana", ("kibana",)),
        ("Elasticsearch", ("elasticsearch", "elastic search")),
        ("Sentry", ("sentry",)),
        ("Android Studio", ("android studio",)),
        ("Xcode", ("xcode",)),
        ("AWS", ("aws", "amazon web services")),
        ("Azure", ("azure",)),
        ("Google Cloud", ("google cloud", "gcp")),
    )

    def enrich(
        self,
        profile: ResumeProfile,
        resume_text: str,
    ) -> ResumeProfile:
        return profile.model_copy(
            update={
                "skills": self._merge(
                    profile.skills,
                    self._extract(resume_text, self.SKILLS),
                ),
                "technologies": self._merge(
                    profile.technologies,
                    self._extract(resume_text, self.TECHNOLOGIES),
                ),
                "preferred_roles": self._merge(
                    profile.preferred_roles,
                    [profile.profession],
                ),
            }
        )

    def _extract(
        self,
        text: str,
        catalogue: tuple[tuple[str, tuple[str, ...]], ...],
    ) -> list[str]:
        normalized = re.sub(r"\s+", " ", text).casefold()

        return [
            label
            for label, aliases in catalogue
            if any(self._contains(normalized, alias) for alias in aliases)
        ]

    def _contains(self, text: str, alias: str) -> bool:
        return re.search(
            rf"(?<!\w){re.escape(alias.casefold())}(?!\w)",
            text,
        ) is not None

    def _merge(
        self,
        primary: list[str],
        detected: list[str],
    ) -> list[str]:
        result: list[str] = []
        seen: set[str] = set()

        for value in [*primary, *detected]:
            for item in re.split(r"[,;\n]+", value):
                normalized = item.strip()

                if not normalized:
                    continue

                key = normalized.casefold()

                if key in seen:
                    continue

                seen.add(key)
                result.append(normalized)

        return result
