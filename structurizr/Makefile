DOCKER ?= docker
IMAGE ?= structurizr/structurizr:latest
CONTAINER ?= structurizr
WS := $(CURDIR)
UID_ARGS := --user $(shell id -u):$(shell id -g)

.PHONY: up down logs export validate clean

up:
	$(DOCKER) run -d --rm --name $(CONTAINER) $(UID_ARGS) -p 8080:8080 -v $(WS):/usr/local/structurizr $(IMAGE) local
	@echo "Structurizr local running at http://localhost:8080"

down:
	$(DOCKER) stop $(CONTAINER)

logs:
	$(DOCKER) logs -f $(CONTAINER)

export:
	mkdir -p static-site
	$(DOCKER) run --rm $(UID_ARGS) -v $(WS):/usr/local/structurizr $(IMAGE) export -workspace workspace.dsl -format static -output static-site
	@echo "Static site written to static-site/ (open static-site/index.html)"

validate:
	$(DOCKER) run --rm $(UID_ARGS) -v $(WS):/usr/local/structurizr $(IMAGE) validate -workspace workspace.dsl

clean:
	rm -rf static-site