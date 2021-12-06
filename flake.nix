{
  description = "A devShell example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-21.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    crate2nix = {
      url = "github:kolloch/crate2nix";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, crate2nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
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
            export ADVENT_LOG="actix_web, advent_of_code_2021"
          '';
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
