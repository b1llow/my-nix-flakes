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
            nativeBuildInputs = with pkgs; [
              bison
              flex
              autoconf
              automake
              libtool
              pkg-config
              python311
              expect
              which
              gawk
            ];
            buildInputs = with pkgs; [
              texinfo
              readline
              ncurses
              zlib
              expat
              dejagnu
              zstd
              gmp
              mpfr
              libmpc
              isl
            ];
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
          pkgs.stdenv.mkDerivation rec {
            pname = "gdb-tricore";
            version = "10.0.50"; # 改成你要的版本

            # 选一种 src：tarball 或你的 Git 仓库
            src = pkgs.fetchFromGitHub {
              owner = "Starforge-Atelier";
              repo = "gdb-tricore";
              rev = "refs/heads/main";
              sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # 用 nix-output 获取真实哈希
            };

            nativeBuildInputs = with pkgs; [
              bison
              flex
              autoconf
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
                readline
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

            # out-of-tree 构建更干净
            preConfigure = ''
              mkdir build
              cd build
            '';
            configureScript = "../configure";
            configureFlags = [
              "--prefix=${placeholder "out"}"
              "--enable-gdb"
              "--disable-binutils" # 如果抓的是 binutils-gdb 合仓，这样只构建 gdb
              "--with-python=${pkgs.python311}"
              "--with-expat"
              "--with-lzma"
              "--with-system-readline"
              "--enable-tui"
              "--target=${target}" # 改成你的 cross 目标即可做 cross-gdb
            ];

            enableParallelBuilding = true;
            doCheck = false; # gdb testsuite 超慢，通常关掉

            meta = with lib; {
              description = "GDB with TriCore architecture support";
              license = licenses.gpl3Plus;
              platforms = platforms.unix;
            };
          };

      }
    );
}
