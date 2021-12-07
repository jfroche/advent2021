{
  description = "A devShell example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-21.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-utils.url = "github:numtide/flake-utils";
    crate2nix = {
      url = "github:kolloch/crate2nix";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, crate2nix, pre-commit-hooks, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        overlays = [ (import rust-overlay) ];
        name = "advent-of-code-2021";
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        inherit (import "${crate2nix}/tools.nix" { inherit pkgs; })
          generatedCargoNix
          ;
        project = pkgs.callPackage
          (generatedCargoNix {
            name = name;
            src = ./.;
          })
          {
            defaultCrateOverrides = pkgs.defaultCrateOverrides // {
              # Crate dependency overrides go here
            };
          };
      in
      with pkgs;
      rec {
        devShell = mkShell {
          buildInputs = [
            rust-bin.nightly.latest.default
            pkgs.rust-analyzer
            pkgs.clippy
            pkgs.rls
            pkgs.jq
          ];
          shellHook = ''
            ${self.checks.${system}.pre-commit-check.shellHook}
            export ADVENT_LOG="actix_web, advent_of_code_2021"
          '';
        };

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              rustfmt.enable = true;
              clippy = {
                enable = true;
                entry = lib.mkForce ''
                  bash -c 'PATH="${rust-bin.nightly.latest.default}/bin:${pkgs.clippy}/bin" cargo clippy -- --deny warnings'
                '';
              };
            };
          };
        };

        packages.${name} = project.rootCrate.build;

        # `nix build`
        defaultPackage = self.packages.${system}.${name};

        # `nix run`
        apps.${name} = flake-utils.lib.mkApp {
          inherit name;
          drv = packages.${name};
        };
        defaultApp = apps.${name};
      }
    );
}
