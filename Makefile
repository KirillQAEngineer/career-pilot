PYTHON ?= apps/api/.venv/bin/python

.PHONY: up down logs api test backend-test frontend-test lint backend-lint frontend-lint docs-build web-build docker-build ci

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f api

api:
	docker compose up -d postgres api

backend-test:
	PYTHONPATH=apps/api $(PYTHON) -m pytest apps/api/tests

frontend-test:
	cd jobcompass_ui && flutter test --coverage

test: backend-test frontend-test

backend-lint:
	PYTHONPATH=apps/api $(PYTHON) -m compileall -q apps/api/app apps/api/alembic/versions

frontend-lint:
	cd jobcompass_ui && dart format --output=none --set-exit-if-changed lib test
	cd jobcompass_ui && flutter analyze --fatal-infos --fatal-warnings

lint: backend-lint frontend-lint

docs-build:
	cd docs && npm ci && npm run build

web-build:
	cd jobcompass_ui && flutter build web --release --base-href /JobCompass/

docker-build:
	docker build --file docker/api/Dockerfile --tag jobcompass-api:local-ci .

ci: lint test docs-build web-build docker-build
