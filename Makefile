.DEFAULT_GOAL := help

help:
	@awk '{FS = ":.*##"} /^[A-z0-9_-]+:.*?##/ {printf "→ \033[36m%-21s\033[0m %s\n", $$1, $$2} /^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)}' $(MAKEFILE_LIST) && echo


##@ DevOps

setup: ## Setups environnment
	pip3 install -e .[test,ci,docs]

setup-dev:  ## Setup development environment
	pip3 install -e .[dev]

dev: ## Run tests on file change
	ptw

test: ## Run tests
	pytest .

build: docs-build


##@ Internal

coverage:  ## Run test coverage
	coverage run -m pytest

report-coverage: coverage  ## Generate HTML coverage report
	coverage html

badge-coverage: coverage  ## Generate coverage badge
	mkdir -p docs/badges
	coverage-badge -f -o docs/badges/coverage.svg

docs-build: badge-coverage report-coverage ## Generate documentation
	mkdocs build
