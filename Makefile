.PHONY: black isort flake8 unittests coverage coveragehtml coveragexml

black:
	${INFO} "Prettifying the code using black..."
	@pipenv run black .

isort:
	${INFO} "Sorting imports by name..."
	@pipenv run isort

flake8:
	${INFO} "Checking compliance with PEP8..."
	@pipenv run flake8

unittests:
	${INFO} "Running unit tests..."
	@pipenv run pytest

mypy:
	${INFO} "Running mypy (checks static types)..."
	@pipenv run mypy

coverage:
	${INFO} "Checking unit test coverage..."
	@pipenv run pytest --cov --cov-fail-under=100

coveragehtml:
	${INFO} "Checking unit test coverage..."
	@pipenv run coverage html

coveragexml:
	${INFO} "Checking unit test coverage..."
	@pipenv run coverage xml

run:
	${INFO} "Running local development server..."
	@pipenv run src/manage.py runserver

pollgists:
	${INFO} "Poll for new gists..."
	@pipenv run src/manage.py gist-poller

# Cosmetics (changing shell colour)
YELLOW := "\e[1;33m"
NO_COLOUR := "\e[0m"

# Shell Functions
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "=> $$1"; \
printf $(NO_COLOUR)' VALUE