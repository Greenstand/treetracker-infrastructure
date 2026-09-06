.PHONY: validate render test
PROFILE ?= production

validate:
	./scripts/validate.sh --profile production
	./scripts/validate.sh --profile kind
	python3 -m unittest discover -s tests -v

render:
	./scripts/render.sh --profile $(PROFILE)

test:
	@test -n "$(CONTEXT)" || (echo 'Set CONTEXT explicitly'; exit 1)
	./scripts/test-network.sh --context "$(CONTEXT)" --profile $(PROFILE)
