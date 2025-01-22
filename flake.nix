{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , crane
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      inherit (pkgs) lib;

      craneLib = crane.mkLib pkgs;

      src = lib.cleanSourceWith {
        src = craneLib.path ./.;
      };

      commonArgs = {
        inherit src;
        strictDeps = true;

        nativeBuildInputs = [
          pkgs.pkg-config
          pkgs.openssl.dev
        ];

        buildInputs =
          [ ]
          ++ lib.optionals pkgs.stdenv.isDarwin [
            pkgs.libiconv
          ];
      };

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      my-crate = craneLib.buildPackage (commonArgs
        // {
        inherit cargoArtifacts;

        meta.mainProgram = "grafana-to-ntfy";
      });
    in
    {
      checks = {
        inherit my-crate;

        my-crate-test = craneLib.cargoTest (commonArgs
          // {
          inherit cargoArtifacts;
        });
      };

      packages.default = my-crate;

      devShells.default = craneLib.devShell {
        checks = self.checks.${system};
        nativeBuildInputs = with pkgs; [
          cargo
          rustc
          rustfmt
          cargo-semver-checks
        ];
      };
    });
}
