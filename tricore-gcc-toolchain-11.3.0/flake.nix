{
  description = "TriCore-enabled GCC 11.3.0 toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        tricoreGccSrc = pkgs.fetchFromGitHub {
          owner = "Starforge-Atelier";
          repo = "tricore-gcc";
          rev = "refs/heads/main";
          sha256 = "sha256-8p73XCEOHZJyQI6mmRDMOh5/KPpaKQOfs6ibRZEnYPw=";
          fetchSubmodules = true;
        };

        tricoreBinutilsSrc = pkgs.fetchFromGitHub {
          owner = "Starforge-Atelier";
          repo = "tricore-binutils-gdb";
          rev = "refs/heads/master";
          sha256 = "sha256-5X+b5DB7tHldk70w+yswpuOXTgI+5w8P8wzRs4YKqAo=";
          fetchSubmodules = true;
        };

        tricoreNewlibSrc = pkgs.fetchFromGitHub {
          owner = "Starforge-Atelier";
          repo = "tricore-newlib-cygwin";
          rev = "refs/heads/master";
          sha256 = "sha256-Ct5+rApyvCbvnOwEBxU1mI8IlZp6eirt3Gxj9xRsxM8=";
          fetchSubmodules = true;
        };

        tricoreSources = pkgs.runCommandNoCC "tricore-toolchain-sources" {}
          ''
            mkdir -p $out
            cp -r ${tricoreGccSrc} $out/gcc
            cp -r ${tricoreBinutilsSrc} $out/binutils
            cp -r ${tricoreNewlibSrc} $out/newlib
          '';
      in {
        packages.default = tricoreSources;
        packages.tricoreSources = tricoreSources;

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
          shellHook = ''
            export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-error"
          '';
        };
      }
    );
}
