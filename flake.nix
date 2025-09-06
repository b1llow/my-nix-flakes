{
  description = "GDB build env on macOS with GCC";

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
          default = pkgs.mkShell.override { stdenv = pkgs.gcc11Stdenv; } {
            inputsFrom = [ self.packages.${system}.default ];
            shellHook = ''
              export CC=gcc
              export CXX=g++
              export M4="$(command -v m4)"
              export GM4="$M4"
              export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-error"
              echo "[gdb-dev:gcc] $(gcc --version | head -1)"
            '';
          };
        };

        packages.default =
          let
            lib = pkgs.lib;
            target = "tricore-elf";
          in
          pkgs.gcc11Stdenv.mkDerivation rec {
            pname = "gdb-tricore";
            version = "10.0.50";

            src = pkgs.fetchFromGitHub {
              owner = "Starforge-Atelier";
              repo = "gdb-tricore";
              rev = "refs/heads/main";
              sha256 = "sha256-ciHqf6XoWHphRSoOkAG1roNqTTx4xsDeAUmv0Bfzj1k="; # 用 nix-output 获取真实哈希
            };

            nativeBuildInputs = with pkgs; [
              bison
              flex
              autoconf269
              automake
              libtool
              pkg-config
              python311
              expect
              which
              gawk
              texinfo
              autoreconfHook
            ];
            buildInputs =
              with pkgs;
              [
                readline70
                ncurses
                zlib
                expat
                dejagnu
                zstd
                gmp
                mpfr
                libmpc
                isl
              ]
              ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];

            preConfigure = ''
              export AUTOCONF=${pkgs.autoconf269}/bin/autoconf
              export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-error"
              echo "Using $(autoconf --version)"
              mkdir build
              cd build
            '';
            configureScript = "../configure";
            configureFlags = [
              "--prefix=${placeholder "out"}"
              "--enable-gdb"
              "--disable-binutils"
              "--with-python=${pkgs.python311}"
              "--with-expat"
              "--with-zstd"
              "--with-system-readline"
              "--enable-tui"
              "--target=${target}"
            ];

            enableParallelBuilding = true;
            doCheck = false;
            dontUpdateAutotoolsGnuConfigScripts = true;
            meta = with lib; {
              description = "GDB with TriCore architecture support";
              license = licenses.gpl3Plus;
              platforms = platforms.unix;
            };
          };

      }
    );
}
