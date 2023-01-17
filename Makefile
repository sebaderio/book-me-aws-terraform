.PHONY: help up-dev pause-dev start-dev stop-dev clean-dev build-dev restart-service-dev reload-service-dev format-api lint-api makemigrations django-dev shell-dev migrate-dev superuser-dev collectstatic-dev

# docker-compose stacks
DEV_COMPOSE=--file docker-compose.yml

# Get SHA and and branch name of git HEAD. Might be useful when running some commands.
SHA1 := $(shell git rev-parse HEAD)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)


# ==========================================================================================================
# Commands for local environment, docker-compose development version
# ==========================================================================================================

# Auto-generate help for each make command with a comment that starts with `##`
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

up-dev: ## create and start services for development (API running on http://localhost:8000, frontend running on: http://localhost:3000)
	docker compose $(DEV_COMPOSE) up -d --build --remove-orphans $(containers)

pause-dev: ## pause development services (useful to save CPU)
	docker compose $(DEV_COMPOSE) pause $(containers)

start-dev: ## start development services
	docker compose $(DEV_COMPOSE) start $(containers)

stop-dev: ## stop development services
	docker compose $(DEV_COMPOSE) stop $(containers)

clean-dev: ## stop and remove containers and volumes for development environment
	docker compose $(DEV_COMPOSE) down --remove-orphans --volumes

build-dev: ## build development services
	docker compose $(DEV_COMPOSE) build --no-cache $(containers)

restart-service-dev: ## restart development service, usage: `make service=api restart-service-dev`
	docker compose $(DEV_COMPOSE) restart $(service)

reload-service-dev: ## reload development service, usage: `make service=api reload-service-dev`
	docker compose $(DEV_COMPOSE) up -d --build --force-recreate $(service)

format-api: ## format code in api
	@docker compose $(DEV_COMPOSE) exec -T api ./scripts/run_code_formatters.sh .

lint-api: ## run linters for api
	@docker compose $(DEV_COMPOSE) exec -T api ./scripts/run_linters.sh .


# ==========================================================================================================
# Django development commands
# ==========================================================================================================

makemigrations: ## generate migrations for django apps, usage: `make apps='barber customer' django-makemigrations`
	docker compose $(DEV_COMPOSE) exec -T api python manage.py makemigrations $(apps)

django-dev: ## run django management commands via make in development environment, usage: `make django-dev cmd='makemigrations barber'`
	docker compose $(DEV_COMPOSE) exec api python manage.py $(cmd)

shell-dev: ## get into django shell in development environment
	docker compose $(DEV_COMPOSE) exec api python manage.py shell

migrate-dev: ## apply migration for django app in development environment, usage: `make app='barber' django-migrate-dev`
	docker compose $(DEV_COMPOSE) exec -T api python manage.py migrate $(app)

superuser-dev: ## create admin account in development environment
	docker compose $(DEV_COMPOSE) exec api python manage.py createsuperuser

collectstatic-dev: ## collect static files needed to make django admin work properly in development environment
	docker compose $(DEV_COMPOSE) exec api python manage.py collectstatic
