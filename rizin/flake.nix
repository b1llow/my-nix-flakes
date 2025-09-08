{
  description = "build environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
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
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
            shellHook = ''
              echo "Welcome to the Rizin development shell!"
            '';
          };
        };
        packages.default =
          let
            ver = "0.8.1";
            rizin-src = builtins.fetchurl {
              url = "https://github.com/rizinorg/rizin/releases/download/v${ver}/rizin-src-v${ver}.tar.xz";
              sha256 = "sha256:1hjf180q4ba0cs5ys7vwy5xs1k6195kransj8fn3dp6p4mjiwazg";
            };
          in
          pkgs.rizin.overrideAttrs (old: {
            pname = "rizin";
            version = "${ver}";
            src = rizin-src;
            patches = builtins.filter (
              x: builtins.baseNameOf x != "0001-fix-compilation-with-clang.patch"
            ) old.patches;

            meta = with pkgs.lib; {
              description = "Rizin - Reverse Engineering Framework";
              license = licenses.lgpl3;
              platforms = platforms.unix;
            };
          });

      }
    );
}
