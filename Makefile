build:
	nix build

run:
	nix run

test:
	cargo test

fmt:
	cargo fmt

day%:
	@curl -s localhost:4000/$@/1 -H "Content-Type: application/json" --data "@inputs/$@.txt" | jq -r '.raw'
	@curl -s localhost:4000/$@/2 -H "Content-Type: application/json" --data "@inputs/$@.txt" | jq -r '.raw'

all: day1 day2
