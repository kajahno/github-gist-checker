

PROJECT ?= gistchecker

NAME ?= gistchecker
ORG_NAME ?= kajahno
REPO_NAME ?= gistchecker

# Application Service Name -> must match Docker Compose service name
APP_SERVICE_NAME := app

startdb:
	${INFO} "Pulling fresh images..."
	@ docker-compose -p $(PROJECT) pull
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(PROJECT) run --rm agent
	${INFO} "Database is up!"

migratedb:
	${INFO} "Making and applying pending migrations using docker container lml lml..."
	@ docker-compose -p $(PROJECT) run --rm app bash -c "src/manage.py makemigrations && src/manage.py migrate"

pollgists:
	${INFO} "Poll for new gists..."
	@ pipenv run src/manage.py gist-poller

buildimage:
	${INFO} "Building docker image..."
	@ docker build -t gist-checker-server .

run: startdb databasemigrationsdocker
	${INFO} "Building images..."
	@ docker-compose -p $(PROJECT) build --pull app
	${INFO} "Bringing up app..."
	@ docker-compose -p $(PROJECT) up -d app
	${INFO} "The app is up and running on http://localhost:8000 "

build:
	${INFO} "Building images..."
	@ docker-compose -p $(PROJECT) build --pull app

clean:
	${INFO} "Destroying dev environment..."
	@ docker-compose -p $(PROJECT) down -v
	${INFO} "Clean complete"

# dockerhub things
tag:
	${INFO} "Tagging image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(TAG_ARGS), docker tag $(IMAGE_ID) $(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging complete"

login:
	${INFO} "Logging in to Docker registry $$DOCKER_REGISTRY..."
	@ docker login
	${INFO} "Logged in to Docker registry $$DOCKER_REGISTRY"

logout:
	${INFO} "Logging out of Docker registry $$DOCKER_REGISTRY..."
	@ docker logout
	${INFO} "Logged out of Docker registry $$DOCKER_REGISTRY"

publish:
	${INFO} "Publishing image ${IMAGE_ID} to ${ORG_NAME}/${REPO_NAME}..."
	@ $(foreach tag,$(shell echo $(REPO_EXPR)), docker push $(tag);)


# Cosmetics (changing shell colour)
YELLOW := "\e[1;33m"
NO_COLOUR := "\e[0m"

# Shell Functions
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "=> $$1"; \
printf $(NO_COLOUR)' VALUE

# Get container id of application service container
APP_CONTAINER_ID := $$(docker-compose -p $(PROJECT) ps -q $(APP_SERVICE_NAME))

# Get image id of application service
IMAGE_ID := $$(docker inspect -f '{{ .Image }}' $(APP_CONTAINER_ID))

# Extract tag arguments
ifeq (tag,$(firstword $(MAKECMDGOALS)))
  TAG_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifeq ($(TAG_ARGS),)
    $(error You must specify a tag)
  endif
  # We need to use this since the list is dynamic and cannot be included into the .PHONY directive 
  $(eval $(TAG_ARGS):;@:)
endif
