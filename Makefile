build:
	nix build

run:
	nix run

test:
	cargo test

fmt:
	cargo fmt

day1:
	@curl -s -X POST localhost:4000/day1/1 -H "Content-Type: application/json" --data "@inputs/day1.txt" | jq -r '.raw'
	@curl -s -X POST localhost:4000/day1/2 -H "Content-Type: application/json" --data "@inputs/day1.txt" | jq -r '.raw'
