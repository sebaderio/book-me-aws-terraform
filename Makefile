.PHONY: help up-dev pause-dev start-dev stop-dev clean-dev build-dev restart-service-dev reload-service-dev up-prod pause-prod start-prod stop-prod clean-prod build-prod restart-service-prod django-makemigrations django-migrate-dev django-migrate-prod django-dev django-prod django-superuser-dev django-superuser-prod

# docker-compose stacks
DEV_COMPOSE=--file docker-compose.dev.yml
PROD_COMPOSE=--file docker-compose.prod.yml

# Get SHA and and branch name of git HEAD. Might be useful when running some commands.
SHA1 := $(shell git rev-parse HEAD)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)


# ==========================================================================================================
# commands for local environment, docker-compose development version
# ==========================================================================================================

# Auto-generate help for each make command with a comment that starts with `##`
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

up-dev: ## create and start services for development (API running on http://localhost:8000, frontend running on: http://localhost:3000)
	docker-compose $(DEV_COMPOSE) up -d --build --remove-orphans $(containers)

pause-dev: ## pause development services (useful to save CPU)
	docker-compose $(DEV_COMPOSE) pause $(containers)

start-dev: ## start development services
	docker-compose $(DEV_COMPOSE) start $(containers)

stop-dev: ## stop development services
	docker-compose $(DEV_COMPOSE) stop $(containers)

clean-dev: ## stop and remove containers and volumes for development environment
	docker-compose $(DEV_COMPOSE) down --remove-orphans --volumes

build-dev: ## build development services
	docker-compose $(DEV_COMPOSE) build --no-cache $(containers)

restart-service-dev: ## restart development service, usage: `make service=api restart-service-dev`
	docker-compose $(DEV_COMPOSE) restart $(service)

reload-service-dev: ## reload development service, usage: `make service=api reload-service-dev`
	docker-compose $(DEV_COMPOSE) up -d --build --force-recreate $(service)

format-api: ## format code in api
	@docker-compose $(DEV_COMPOSE) exec -T api ./scripts/run_code_formatters.sh .

lint-api: ## run linters for api
	@docker-compose $(DEV_COMPOSE) exec -T api ./scripts/run_linters.sh .


# ==========================================================================================================
# commands for production environment, docker-compose production version
# ==========================================================================================================

up-prod: ## create and start services for production environment
	docker-compose $(PROD_COMPOSE) up -d --build --remove-orphans

pause-prod: ## pause production services (useful to save CPU)
	docker-compose $(PROD_COMPOSE) pause $(containers)

start-prod: ## start production services
	docker-compose $(PROD_COMPOSE) start $(containers)

stop-prod: ## stop production services
	docker-compose $(PROD_COMPOSE) stop $(containers)

clean-prod: ## stop and remove containers and volumes for production environment
	docker-compose $(PROD_COMPOSE) down --remove-orphans --volumes

build-prod: ## build production services
	docker-compose $(PROD_COMPOSE) build --no-cache $(containers)

restart-service-prod: ## restart production service, usage: `make service=api restart-service-prod`
	docker-compose $(PROD_COMPOSE) restart $(service)

reload-service-prod: ## reload production service, usage: `make service=api reload-service-prod`
	docker-compose $(PROD_COMPOSE) up -d --build --force-recreate $(service)


# ==========================================================================================================
# Django development commands
# ==========================================================================================================

makemigrations: ## generate migrations for django apps, usage: `make apps='barber customer' django-makemigrations`
	docker-compose $(DEV_COMPOSE) exec -T api python manage.py makemigrations $(apps)

django-dev: ## run django management commands via make in development environment, usage: `make django-dev cmd='makemigrations barber'`
	docker-compose $(DEV_COMPOSE) exec api python manage.py $(cmd)

shell-dev: ## get into django shell in development environment
	docker-compose $(DEV_COMPOSE) exec api python manage.py shell

migrate-dev: ## apply migration for django app in development environment, usage: `make app='barber' django-migrate-dev`
	docker-compose $(DEV_COMPOSE) exec -T api python manage.py migrate $(app)

superuser-dev: ## create admin account in development environment
	docker-compose $(DEV_COMPOSE) exec api python manage.py createsuperuser

collectstatic-dev: ## collect static files needed to make django admin work properly in development environment
	docker-compose $(DEV_COMPOSE) exec api python manage.py collectstatic


# ==========================================================================================================
# Django production commands
# ==========================================================================================================

django-prod: ## run django management commands via make in production environment, usage: `make django-prod cmd='migrate barber'`
	docker-compose $(PROD_COMPOSE) exec api python manage.py $(cmd)

shell-prod: ## get into django shell in production environment
	docker-compose $(PROD_COMPOSE) exec api python manage.py shell

migrate-prod: ## apply migration for django app in production environment, usage: `make app='barber' django-migrate-prod`
	docker-compose $(PROD_COMPOSE) exec -T api python manage.py migrate $(app)

superuser-prod: ## create admin account in production environment
	docker-compose $(PROD_COMPOSE) exec api python manage.py createsuperuser

collectstatic-prod: ## collect static files needed to make django admin work properly in production environment
	docker-compose $(PROD_COMPOSE) exec api python manage.py collectstatic
