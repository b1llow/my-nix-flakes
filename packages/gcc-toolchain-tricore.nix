{
  description = "TriCore-enabled GCC 11.3.0 toolchain";

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
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs)
          lib
          gmp
          mpfr
          libmpc
          isl
          zlib
          bison
          flex
          texinfo
          libtool
          pkg-config
          python311
          expect
          which
          gawk
          zstd
          expat
          gettext
          gnused
          perl
          ;
        mystdenv = pkgs.gcc11Stdenv;
        inherit (mystdenv) hostPlatform;

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

        configCommon = {
          nativeBuildInputs = [
            texinfo
            which
            gettext
            flex
            bison
            pkg-config
            perl
          ];
          buildInputs = [
            gmp
            mpfr
            libmpc
            zlib
            zstd
            isl
          ]
          ++ (lib.optional hostPlatform.isDarwin gnused);
          enableParallelBuilding = true;
          dontUpdateAutotoolsGnuConfigScripts = true;
          meta.platforms = pkgs.lib.platforms.unix;
        };

        binutilsConfigureFlags = [
          "--disable-nls"
          "--disable-werror"
          "--disable-readline"
          "--disable-libdecnumber"
          "--disable-threads"
          "--disable-itcl"
          "--disable-tk"
          "--disable-tcl"
          "--disable-winsup"
          "--disable-gdbtk"
          "--disable-libgui"
          "--disable-rda"
          "--disable-sid"
          "--disable-sim"
          "--disable-gdb"
          "--disable-newlib"
          "--disable-libgloss"
          "--disable-test-suite"
          "--enable-checking=release"
          "--with-gnu-ld"
          "--with-gnu-as"
          "--enable-64-bit-bfd"
        ];

        target-name = "tricore-elf";
        program-prefix = "${target-name}-";

        tricore-binutils-mcs = mystdenv.mkDerivation (
          configCommon
          // {
            pname = "binutils-mcs-elf";
            version = "2.42";
            src = tricoreBinutilsSrc;
            configureFlags = [
              "--target=mcs-elf"
              "--program-prefix=mcs-elf-"
            ]
            ++ binutilsConfigureFlags;
          }
        );

        tricore-binutils = mystdenv.mkDerivation (
          configCommon
          // {
            pname = "binutils-${target-name}";
            version = "2.42";
            src = tricoreBinutilsSrc;
            buildInputs = configCommon.buildInputs ++ [ tricore-binutils-mcs ];
            nativeBuildInputs = configCommon.nativeBuildInputs ++ [ tricore-binutils-mcs ];
            configureFlags = [
              "--target=${target-name}"
              "--enable-targets=mcs-elf"
              "--program-prefix=${program-prefix}"
            ]
            ++ binutilsConfigureFlags;
          }
        );

        gccConfigureFlags = [
          "--target=${target-name}"
          "--enable-lib32"
          "--disable-lib64"
          "--enable-languages=c,c++"
          "--enable-c99"
          "--enable-long-long"
          "--enable-checking"
          "--with-headers=yes"
          "--with-newlib=yes"
          "--disable-nls"
          "--disable-shared"
          "--disable-threads"
          "--enable-mingw-wildcard"
          "--disable-libstdcxx-pch"
          "--enable-newlib-elix-level=3"
          "--enable-newlib-io-long-long"
          "--disable-newlib-supplied-syscalls"
          "--disable-libssp"
          "--disable-test-suite"
          "--disable-lto"
          "--with-as=${tricore-binutils}/bin/${program-prefix}as"
          "--with-ld=${tricore-binutils}/bin/${program-prefix}ld"
        ];

        tricore-gcc-stage1 = mystdenv.mkDerivation (
          configCommon
          // {
            pname = "gcc11-${target-name}-stage1";
            version = "11.3.0";
            src = tricoreGccSrc;
            buildInputs = configCommon.buildInputs ++ [ tricore-binutils ];
            nativeBuildInputs = configCommon.nativeBuildInputs ++ [ tricore-binutils ];
            configureFlags = gccConfigureFlags;
            hardeningDisable = [ "format" ];
            makeFlags = [
              "all-gcc"
            ];
            installTargets = "install-gcc";
          }
        );

        tricore-newlib = mystdenv.mkDerivation (
          configCommon
          // {
            pname = "newlib-${target-name}";
            version = "4.3.0";
            src = tricoreNewlibSrc;
            buildInputs = configCommon.buildInputs ++ [
              tricore-binutils
              tricore-gcc-stage1
            ];
            nativeBuildInputs = configCommon.nativeBuildInputs ++ [
              tricore-binutils
              tricore-gcc-stage1
            ];
            preConfigure = ''
              	export CC_FOR_TARGET=${tricore-gcc-stage1}/bin/${program-prefix}gcc
              	export CXX_FOR_TARGET=${tricore-gcc-stage1}/bin/${program-prefix}c++
              	export AR_FOR_TARGET=${tricore-binutils}/bin/${program-prefix}ar
              	export AS_FOR_TARGET=${tricore-binutils}/bin/${program-prefix}as
              	export LD_FOR_TARGET=${tricore-binutils}/bin/${program-prefix}ld
              	export NM_FOR_TARGET=${tricore-binutils}/bin/${program-prefix}nm
              	export OBJDUMP_FOR_TARGET=${tricore-binutils}/bin/${program-prefix}objdump
              	export RANLIB_FOR_TARGET=${tricore-binutils}/bin/${program-prefix}ranlib
              	export STRIP_FOR_TARGET=${tricore-binutils}/bin/${program-prefix}strip
              	export READELF_FOR_TARGET=${tricore-binutils}/bin/${program-prefix}readelf
            '';
            configureFlags = [
              "--target=${target-name}"
            ];
          }
        );

        tricore-gcc = mystdenv.mkDerivation (
          configCommon
          // {
            pname = "gcc11-${target-name}";
            version = "11.3.0";
            src = tricoreGccSrc;
            buildInputs = configCommon.buildInputs ++ [
              tricore-binutils
              tricore-newlib
            ];
            nativeBuildInputs = configCommon.nativeBuildInputs ++ [
              tricore-binutils
              tricore-newlib
            ];
            configureFlags = gccConfigureFlags ++ [
              "--with-sysroot=${tricore-newlib}/${target-name}"
              "--with-native-system-header-dir=/include"
            ];
            preConfigure = ''
              mkdir build && cd build
            '';
            configureScript = ''
              ../configure
            '';
            hardeningDisable = [ "format" ];
            makeFlags = [
              "all-gcc"
              "all-target-libgcc"
            ];
            installTargets = "install-gcc install-target-libgcc";
          }
        );

        tricore-toolchain = pkgs.symlinkJoin {
          name = "tricore-elf-toolchain";
          paths = [
            tricore-binutils
            tricore-gcc
            tricore-newlib
          ];
        };
      in
      {
        packages = {
          inherit tricore-binutils-mcs;
          inherit tricore-binutils;
          inherit tricore-newlib;
          inherit tricore-gcc-stage1;
          inherit tricore-gcc;
          inherit tricore-toolchain;
          default = tricore-toolchain;
        };
      }
    );
}
