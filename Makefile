.PHONY: ci

build:
	nix build

build-image:
	nix build .#dockerImage

load-image: build-image
	docker load -i "$(shell nix path-info -L '.#dockerImage')"

run:
	nix run

test:
	cargo test

fmt:
	treefmt

lint:
	pre-commit run --all

ci:
	cd ci && just

clean:
	rm -fr target result

day%:
	@curl -s localhost:4000/$@/1 -H "Content-Type: application/json" --data "@inputs/$@.json" | jq -r '.raw'
	@curl -s localhost:4000/$@/2 -H "Content-Type: application/json" --data "@inputs/$@.json" | jq -r '.raw'

all: day1 day2
