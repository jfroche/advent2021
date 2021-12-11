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
	{
		file:   "docker.yml"
		schema: docker
	},

]

docker: _#bashWorkflow & {

	name: "Docker"
	on: {
		workflow_run: {
			workflows: ["Tests"]
			branches: ["main"]
			types: ["completed"]
		}
		push: {
			branches: ["**"]
			"tags-ignore": [_#releaseTagPattern]
		}
		pull_request: {}
	}
	jobs: {
		build: {
			"runs-on": _#linuxMachine
			steps: [
				_#installNix,
				_#checkoutCode,
				_#loadDockerImage,
				_#cleanupGit,
			]
		}
	}
}

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
			"runs-on": _#linuxMachine
			steps: [
				_#installNix,
				_#checkoutCode,
				_#runLint,
				_#cleanupGit,
			]
		}
		test: {
			"runs-on": _#linuxMachine
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

_#runMakeInNixShell: "nix develop --ignore-environment -c make "

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

_#loadDockerImage: _#step & {
	name: "Load docker image"
	run:  "make load-image"
}
