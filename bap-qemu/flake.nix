{
  description = "BAP QEMU";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlay.url = "github:nix-ocaml/nix-overlays";
    ocaml-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ocaml-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            ocaml-overlay.overlays.default
          ];
        };
        ocaml414 = (pkgs.ocaml-ng.ocamlPackages_4_14 or pkgs.ocamlPackages_4_14);

        qemuBase = pkgs.qemu.override {
          enableDocs = false;
        };
        qemuBAP = qemuBase.overrideAttrs (old: rec {
          version = "10.0.2+bap";
          src = pkgs.fetchFromGitHub {
            owner = "Starforge-Atelier";
            repo = "qemu";
            rev = "refs/heads/trace-10-tricore";
            sha256 = "sha256-k/IKmU3qIUcXqWLNVc73f6iB1hv9Gb/eMKstn/UkUzU=";
            fetchSubmodules = true;
            postFetch = ''
              cd "$out"
              for prj in subprojects/*.wrap; do
                ${pkgs.lib.getExe pkgs.meson} subprojects download "$(basename "$prj" .wrap)"
              done
              find subprojects -type d -name .git -prune -execdir rm -r {} +
            '';
          };

          configureFlags = [
            "--enable-debug"
            "--enable-asan"
            "--without-default-features"
            "--target-list=tricore-softmmu"
            "--enable-plugins"
            "--enable-user"
            "--enable-system"
            "--disable-docs"
          ];

          nativeBuildInputs =
            with pkgs;
            (old.nativeBuildInputs or [ ])
            ++ [
              ocaml414.piqi
            ];
          buildInputs =
            with pkgs;
            (old.buildInputs or [ ])
            ++ [
              protobufc
            ];

          postInstall =
            let
              libExt = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
            in
            "
            mkdir -p $out/plugins
            cp ./contrib/plugins/*${libExt} $out/plugins/
            cp ./contrib/plugins/bap-tracing/*${libExt} $out/plugins/
          ";

          meta = old.meta // {
            homepage = "https://github.com/BinaryAnalysisPlatform/qemu";
            # mainProgram = "qemu-system-tricore";
            # maintainers = oldAttrs.meta.maintainers ++ [ lib.maintainers.sfrijters ];
          };

        });

      in
      {
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
            shellHook = ''export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-error"'';
          };
        };

        packages.default = qemuBAP;

      }
    );
}
