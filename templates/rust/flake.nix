{
  description = "Rust app template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs)
          lib
          nixfmt-tree
          rustPlatform
          mkShell
          rust-analyzer
          cargo-watch
          ;
      in
      {
        formatter = nixfmt-tree;

        packages = {
          default = rustPlatform.buildRustPackage rec {
            pname = "app";
            version = "0.1.0";
            src = ./.;

            cargoLock.lockFile = ./Cargo.lock;

            cargoHash = "";

            # 需要系统库时解除注释（示例：OpenSSL）
            # nativeBuildInputs = [ pkgs.pkg-config ];
            # buildInputs = [ pkgs.openssl ];

            # macOS 可能需要的系统框架（按需开启）
            # buildInputs = (buildInputs or []) ++ lib.optionals pkgs.stdenv.isDarwin [
            #   pkgs.darwin.apple_sdk.frameworks.Security
            # ];
          };
        };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/app";
          };
        };

        checks = {
          build = self.packages.${system}.default;
        };

        devShells = {
          default = mkShell {
            inputsFrom = [
              self.packages.${system}.default
            ];
            packages = [
              rust-analyzer
              cargo-watch
            ];
            RUST_SRC_PATH = "${rustPlatform.rustLibSrc}";
            shellHook = ''echo "🦀 Rust dev shell ready. Try: cargo run"'';
          };
          fmt = mkShell {
            packages = [
              rustPlatform.rust.cargo
            ];
          };
        };

      }
    );
}
