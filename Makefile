.PHONY: docs tests src

setup:
	pip3 install -e .[test,docs,ci]

setup-dev:
	pip3 install -e .[dev,test]

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

docs-deploy:
	echo $(shell git describe --tags --exact-match || git rev-parse --abbrev-ref HEAD)
	mike deploy \
		--push $(shell git describe --tags --exact-match || git rev-parse --abbrev-ref HEAD) \
		--allow-empty

build: docs-build docs-deploy