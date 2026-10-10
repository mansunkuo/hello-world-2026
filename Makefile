.PHONY: up down logs export export-saved validate clean

up:
	$(MAKE) -C structurizr up
down:
	$(MAKE) -C structurizr down
logs:
	$(MAKE) -C structurizr logs
export:
	$(MAKE) -C structurizr export
export-saved:
	$(MAKE) -C structurizr export-saved
validate:
	$(MAKE) -C structurizr validate
clean:
	$(MAKE) -C structurizr clean