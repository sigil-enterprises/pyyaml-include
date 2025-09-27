.PHONY: docs tests src

setup:
	pip3 install -e .[test,ci,docs]

setup-dev:
	pip3 install -e .[dev]

test:
	pytest .

dev:
	ptw

coverage:
	coverage run -m pytest

report-coverage: coverage
	coverage html

badge-coverage: coverage
	mkdir -p docs/badges
	coverage-badge -f -o docs/badges/coverage.svg

docs-build: badge-coverage report-coverage
	mkdocs build

build: docs-build