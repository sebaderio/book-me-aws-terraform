.PHONY: help up pause start stop clean build restart-service reload-service format-api lint-api makemigrations django shell migrate superuser collectstatic

# docker-compose stacks
DEV_COMPOSE=--file docker-compose.yml

# Get SHA and and branch name of git HEAD. Might be useful when running some commands.
SHA1 := $(shell git rev-parse HEAD)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)


# ==========================================================================================================
# Commands for local environment, docker compose development version
# ==========================================================================================================

# Auto-generate help for each make command with a comment that starts with `##`
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

up: ## create and start services for development (API running on http://localhost:8000, frontend running on: http://localhost:3000)
	docker compose $(DEV_COMPOSE) up -d --build --remove-orphans $(containers)

pause: ## pause development services (useful to save CPU)
	docker compose $(DEV_COMPOSE) pause $(containers)

start: ## start development services
	docker compose $(DEV_COMPOSE) start $(containers)

stop: ## stop development services
	docker compose $(DEV_COMPOSE) stop $(containers)

clean: ## stop and remove containers and volumes for development environment
	docker compose $(DEV_COMPOSE) down --remove-orphans --volumes

build: ## build development services
	docker compose $(DEV_COMPOSE) build --no-cache $(containers)

restart-service: ## restart development service, usage: `make service=api restart-service`
	docker compose $(DEV_COMPOSE) restart $(service)

reload-service: ## reload development service, usage: `make service=api reload-service`
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

django: ## run django management commands via make in development environment, usage: `make django cmd='makemigrations barber'`
	docker compose $(DEV_COMPOSE) exec api python manage.py $(cmd)

shell: ## get into django shell in development environment
	docker compose $(DEV_COMPOSE) exec api python manage.py shell

migrate: ## apply migration for django app in development environment, usage: `make app='barber' django-migrate`
	docker compose $(DEV_COMPOSE) exec -T api python manage.py migrate $(app)

superuser: ## create admin account in development environment
	docker compose $(DEV_COMPOSE) exec api python manage.py createsuperuser

collectstatic: ## collect static files needed to make django admin work properly in development environment
	docker compose $(DEV_COMPOSE) exec api python manage.py collectstatic
