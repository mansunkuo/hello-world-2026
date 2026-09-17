.PHONY: up down logs export validate clean

up:
	$(MAKE) -C structurizr up
down:
	$(MAKE) -C structurizr down
logs:
	$(MAKE) -C structurizr logs
export:
	$(MAKE) -C structurizr export
validate:
	$(MAKE) -C structurizr validate
clean:
	$(MAKE) -C structurizr clean