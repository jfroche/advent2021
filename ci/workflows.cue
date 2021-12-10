package ci

import (
	"github.com/SchemaStore/schemastore/src/schemas/json"
)

workflowsDir: *"./" | string @tag(workflowsDir)

_#masterBranch:      "master"
_#releaseTagPattern: "v*"

workflows: [...{file: string, schema: (json.#Workflow & {})}]
workflows: [
	{
		file:   "test.yml"
		schema: test
	},
]

test: _#bashWorkflow & {

	name: "Tests"
	on: {
		push: {
			branches: ["**"] // any branch (including '/' namespaced branches)
			"tags-ignore": [_#releaseTagPattern]
		}
		pull_request: {}
	}

	jobs: {
		lint: {
			strategy:  _#testStrategy
			"runs-on": "${{ matrix.os }}"
			steps: [
				_#installNix,
				_#checkoutCode,
				_#runLint,
				_#cleanupGit,
			]
		}
		test: {
			strategy:  _#testStrategy
			"runs-on": "${{ matrix.os }}"
			steps: [
				_#installNix,
				_#checkoutCode,
				_#runTest,
				_#cleanupGit,
			]
		}

	}
}

_#bashWorkflow: json.#Workflow & {
	jobs: [string]: defaults: run: shell: "bash"
}

// TODO: drop when cuelang.org/issue/390 is fixed.
// Declare definitions for sub-schemas
_#job:  ((json.#Workflow & {}).jobs & {x: _}).x
_#step: ((_#job & {steps:                 _}).steps & [_])[0]

_#linuxMachine: "ubuntu-20.04"
_#macosMachine: "macos-11"

_#runMakeInNixShell: "nix develop -c make "

_#testStrategy: {
	"fail-fast": false
	matrix: {
		os: [_#linuxMachine, _#macosMachine]
	}
}

_#checkoutCode: _#step & {
	name: "Checkout code"
	uses: "actions/checkout@v2"
}

_#cleanupGit: _#step & {
	name: "Check clean checkout"
	uses: "numtide/clean-git-action@v1"
}

_#installNix: _#step & {
	name: "Install nix"
	uses: "cachix/install-nix-action@v16"
}

_#runTest: _#step & {
	name: "Test"
	run:  _#runMakeInNixShell + "test"
}

_#runLint: _#step & {
	name: "Lint"
	run:  _#runMakeInNixShell + "lint"
}
