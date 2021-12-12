{
  description = "A devShell example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-21.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    crate2nix = {
      flake = false;
      type = "github";
      owner = "balsoft";
      repo = "crate2nix";
      ref = "balsoft/fix-broken-ifd";
    };
  };

  outputs =
    { self
    , nixpkgs
    , rust-overlay
    , flake-utils
    , crate2nix
    , pre-commit-hooks
    , nix-filter
    , ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
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
          src = nix-filter.lib {
            root = ./.;
            include = [
              (nix-filter.lib.inDirectory "src")
              ./Cargo.lock
              ./Cargo.toml
            ];
          };
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
          rust-bin.nightly."2021-12-06".default
          pkgs.rust-analyzer
          pkgs.gcc-unwrapped
          pkgs.go
          pkgs.cue
          pkgs.just
          pkgs.gnumake
          pkgs.rls
          pkgs.jq
          pkgs.git
        ];
        shellHook = ''
          ${self.checks.${system}.pre-commit-check.shellHook}
          export RUSTFLAGS="-C target-feature=-crt-static"
          export ADVENT_LOG="actix_web, advent_of_code_2021"
        '';
      };

      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            rustfmt.enable = true;
            cue = {
              enable = true;
              name = "Cue";
              entry = "make ci";
              files = "\\.(cue)$";
              pass_filenames = false;
            };
            clippy = {
              enable = false;
              entry = lib.mkForce ''
                bash -c 'PATH="${pkgs.binutils.bintools}/bin:${pkgs.gcc-unwrapped}/bin:${rust-bin.nightly."2021-12-06".default}/bin:${pkgs.clippy}/bin:$PATH" cargo clippy -- --deny warnings'
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
      packages.dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "advent2021";
        tag = "latest";

        config = {
          Entrypoint = [ "advent-of-code-2021" ];
          Env = [
            "PATH=${defaultPackage}/bin/"
            "ADVENT_LOG=actix_web, advent_of_code_2021"
          ];
          ExposedPorts = {
            "4000/tcp" = { };
          };
        };
      };
    }
    );
}
