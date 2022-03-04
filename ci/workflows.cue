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
	}
	jobs: {
		build: {
			"runs-on": _#linuxMachine
			"if":      "${{ github.event.workflow_run.conclusion == 'success' }}"
			steps: [
				_#installNix,
				_#installCachix,
				_#checkoutCode,
				_#loadDockerImage,
				_#publishImage,
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
		fmt: {
			"runs-on": _#linuxMachine
			steps: [
				_#installNix,
				_#installCachix,
				_#checkoutCode,
				_#runFmt,
				_#cleanupGit,
			]
		}
		lint: {
			"runs-on": _#linuxMachine
			steps: [
				_#installNix,
				_#installCachix,
				_#checkoutCode,
				_#runLint,
				_#cleanupGit,
			]
		}
		test: {
			"runs-on": _#linuxMachine
			steps: [
				_#installNix,
				_#installCachix,
				_#checkoutCode,
				_#runTestWithNix,
				_#cleanupGit,
			]
		}
		"test-cached-cargo": {
			"runs-on": _#linuxMachine
			steps: [
				_#installNix,
				_#installCachix,
				_#checkoutCode,
				_#cacheCargoRegistry,
				_#cacheCargoTarget,
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

_#runInNixShell: "nix develop --ignore-environment -c "

_#runMakeInNixShell: _#runInNixShell + "make "

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

_#installCachix: _#step & {
	name: "Install cachix"
	uses: "cachix/cachix-action@v10"
	with: {
		name:           "advent-2021"
		authToken:      "${{ secrets.CACHIX_AUTH_TOKEN }}"
		extraPullNames: "nix-community"
		pushFilter:     "(-source$)"
	}
}

_#loginDockerRegistry: _#step & {
	name: "Login on docker registry"
	uses: "docker/login-action@v1"
	with: {
		registry: "ghcr.io"
		username: "${{ github.actor }}"
		password: "${{ secrets.GITHUB_TOKEN }}"
	}
}

_#publishImage: _#step & {
	name: "Publish docker image"
	run: """
		LOADED_IMAGE="${GITHUB_REPOSITORY#*/}:latest"
		IMAGE_NAME="ghcr.io/$(echo "$GITHUB_REPOSITORY"):${GITHUB_SHA}"
		IMAGE_NAME_LATEST="ghrc.io/$(echo "$GITHUB_REPOSITORY"):latest"
		docker tag $LOADED_IMAGE $IMAGE_NAME
		docker tag $LOADED_IMAGE $IMAGE_NAME_LATEST
		docker push "$IMAGE_NAME"
		docker push "$IMAGE_NAME_LATEST"
		"""
}

_#runTest: _#step & {
	name: "Test"
	run:  _#runMakeInNixShell + "test"
}

_#runTestWithNix: _#step & {
	name: "Test"
	run:  "make build"
}

_#runLint: _#step & {
	name: "Lint"
	run:  _#runMakeInNixShell + "lint"
}

_#runFmt: _#step & {
	name: "Check fmt"
	run:  _#runInNixShell + "treefmt --fail-on-change"
}

_#loadDockerImage: _#step & {
	name: "Load docker image"
	run:  "make load-image"
}

_#cacheCargoRegistry: _#step & {
	name: "Cache cargo registry"
	uses: "actions/cache@v2"
	with: {
		path: "~/.cargo"
		key:  "cargo-registry-${{ hashFiles('**/Cargo.lock') }}"
	}
}

_#cacheCargoTarget: _#step & {
	name: "Cache cargo target"
	uses: "actions/cache@v2"
	with: {
		path: "target"
		key:  "cargo-target-${{ hashFiles('**/Cargo.lock') }}"
	}

}
