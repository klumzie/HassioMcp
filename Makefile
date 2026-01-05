.PHONY: help build up down logs restart clean install dev test lint

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	npm install

dev: ## Run in development mode
	npm run dev

build: ## Build TypeScript
	npm run build

docker-build: ## Build Docker image
	docker-compose build

up: ## Start Docker containers
	docker-compose up -d

down: ## Stop Docker containers
	docker-compose down

logs: ## Show Docker logs
	docker-compose logs -f

restart: ## Restart Docker containers
	docker-compose restart

clean: ## Clean build artifacts and containers
	npm run clean
	docker-compose down -v
	rm -rf node_modules

test: ## Run tests
	npm test

test-coverage: ## Run tests with coverage
	npm run test:coverage

lint: ## Run linter
	npm run lint

health: ## Check server health
	curl http://localhost:3000/health

status: ## Show Docker container status
	docker-compose ps
