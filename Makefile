# Watermarked by tc from github.com/sigil-enterprises/sigil-toolchain@v0.39.2
#
ROOT := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
include $(ROOT).toolkit/targets/type.mk

COMPOSE_FILE ?= docker-compose.yaml
COMPOSE ?= docker compose -f $(COMPOSE_FILE)
LOG_TAIL ?= 200

.DEFAULT_GOAL := help

.PHONY: setup setup-dev lock dev test lint coverage docs docs-dev docs-release git-config help check _check_required dc-up dc-down dc-logs dc-build dc-nuke

##@ Help

help: ## Show this help
	@awk 'BEGIN {FS=":.*##"; printf "\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } END { printf "\n" }' $(MAKEFILE_LIST)

##@ Setup

setup: ## Install dependencies
	uv sync

setup-dev: git-config ## Setup development environment
	uv sync --extra dev

lock: ## Generate / update uv.lock
	uv lock

##@ Development

dev: ## Run tests on file change
	uv run ptw

test: ## Run tests
	uv run pytest .

lint: ## Run linter
	@echo "ERROR: lint not implemented — add your lint command (e.g. uv run ruff check src/ tests/)" && exit 1

coverage: ## Run tests with coverage
	uv run pytest --cov=src --cov-report=html --cov-report=xml .

##@ Documentation

docs: ## Build documentation
	uv run mkdocs build --config-file mkdocs.yaml

docs-dev: ## Build and stage dev docs (run inside devcontainer)
	uv run mike deploy dev --config-file mkdocs.yaml

docs-release: ## Build and stage release docs (requires VERSION=x.y.z)
	@test -n "$(VERSION)" || (echo "VERSION is required — use make docs-release VERSION=x.y.z" && exit 1)
	uv run mike deploy --update-aliases "$(VERSION)" latest --config-file mkdocs.yaml

##@ Docker Compose

dc-up: ## Compose up (build)
	$(COMPOSE) up -d --build

dc-down: ## Compose down
	$(COMPOSE) down --remove-orphans

dc-logs: ## Follow compose logs
	$(COMPOSE) logs -f --tail=$(LOG_TAIL)

dc-build: ## Compose build
	$(COMPOSE) build

dc-nuke: ## Stop containers + remove images (keeps volumes)
	$(COMPOSE) down --remove-orphans
	-docker rmi $$(docker images -q --filter "reference=*/${PROJECT}*") 2>/dev/null || true

##@ Internal

git-config: ## Configure git to push into current organization
	git config --global --replace-all \
		url."https://github.com/$$ORGANIZATION/".insteadOf \
		"https://github.com/sigil-enterprises/"
