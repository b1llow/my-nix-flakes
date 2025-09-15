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
        inherit (pkgs) lib nixfmt-tree;
      in
      {
        formatter = nixfmt-tree;

        packages = {
          default = pkgs.rustPlatform.buildRustPackage rec {
            pname = "app";
            version = "0.1.0";
            src = ./.;

            cargoLock.lockFile = ./Cargo.lock;

            # 首次 nix build 会报错给出真实 hash；将其替换掉 pkgs.lib.fakeHash
            cargoHash = pkgs.lib.fakeHash;

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

        # nix flake check 会实际构建一次（也会跑 cargo test，见下）
        checks = {
          build = self.packages.${system}.default;
        };

        devShells = {
          default = pkgs.mkShell {
            inputFrom = self.packages.${system}.default;
            packages = [
              pkgs.rust-analyzer
              pkgs.cargo-watch
            ];
            shellHook = ''echo "🦀 Rust dev shell ready. Try: cargo run"'';
          };
        };

      }
    );
}
