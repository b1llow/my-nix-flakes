{
  gmp,
  mpfr,
  libmpc,
  isl,
  zlib,
  bison,
  flex,
  texinfo,
  libtool,
  pkg-config,
  python311,
  expect,
  which,
  gawk,
  zstd,
  expat,
  gettext,
  gnused,
  perl,

  symlinkJoin,
  fetchFromGitHub,
  lib,
  gccStdenv,
  ...
}:

let
  inherit (gccStdenv) hostPlatform;

  gccSrc = fetchFromGitHub {
    owner = "Starforge-Atelier";
    repo = "tricore-gcc";
    rev = "refs/heads/main";
    sha256 = "sha256-8p73XCEOHZJyQI6mmRDMOh5/KPpaKQOfs6ibRZEnYPw=";
    fetchSubmodules = true;
  };

  binutilSrc = fetchFromGitHub {
    owner = "Starforge-Atelier";
    repo = "tricore-binutils-gdb";
    rev = "refs/heads/master";
    sha256 = "sha256-5X+b5DB7tHldk70w+yswpuOXTgI+5w8P8wzRs4YKqAo=";
    fetchSubmodules = true;
  };

  newlibSrc = fetchFromGitHub {
    owner = "Starforge-Atelier";
    repo = "tricore-newlib-cygwin";
    rev = "refs/heads/master";
    sha256 = "sha256-Ct5+rApyvCbvnOwEBxU1mI8IlZp6eirt3Gxj9xRsxM8=";
    fetchSubmodules = true;
  };

  configCommon = rec {
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
    CFLAGS = "-Wno-error -Wno-error=incompatible-pointer-types";
    CXXFLAGS = "${CFLAGS}";
    enableParallelBuilding = true;
    dontUpdateAutotoolsGnuConfigScripts = true;
    meta.platforms = lib.platforms.unix;
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

  target = "tricore-elf";
  program-prefix = "${target}-";

  binutils-mcs-elf = gccStdenv.mkDerivation (
    configCommon
    // {
      pname = "binutils-mcs-elf";
      version = "2.42";
      src = binutilSrc;
      configureFlags = [
        "--target=mcs-elf"
        "--program-prefix=mcs-elf-"
      ]
      ++ binutilsConfigureFlags;
    }
  );

  binutils = gccStdenv.mkDerivation (
    configCommon
    // {
      pname = "binutils-${target}";
      version = "2.42";
      src = binutilSrc;
      buildInputs = configCommon.buildInputs ++ [ binutils-mcs-elf ];
      nativeBuildInputs = configCommon.nativeBuildInputs ++ [ binutils-mcs-elf ];
      configureFlags = [
        "--target=${target}"
        "--enable-targets=mcs-elf"
        "--program-prefix=${program-prefix}"
      ]
      ++ binutilsConfigureFlags;
    }
  );

  gccConfigureFlags = [
    "--target=${target}"
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
    "--with-as=${binutils}/bin/${program-prefix}as"
    "--with-ld=${binutils}/bin/${program-prefix}ld"
  ];

  gcc-stage1 = gccStdenv.mkDerivation (
    configCommon
    // {
      pname = "gcc-stage1-${target}";
      version = "11.3.0";
      src = gccSrc;
      buildInputs = configCommon.buildInputs ++ [ binutils ];
      nativeBuildInputs = configCommon.nativeBuildInputs ++ [ binutils ];
      configureFlags = gccConfigureFlags;
      hardeningDisable = [ "format" ];
      makeFlags = [
        "all-gcc"
      ];
      installTargets = "install-gcc";
    }
  );

  newlib = gccStdenv.mkDerivation (
    configCommon
    // {
      pname = "newlib-${target}";
      version = "4.3.0";
      src = newlibSrc;
      buildInputs = configCommon.buildInputs ++ [
        binutils
        gcc-stage1
      ];
      nativeBuildInputs = configCommon.nativeBuildInputs ++ [
        binutils
        gcc-stage1
      ];
      preConfigure = ''
        	export CC_FOR_TARGET=${gcc-stage1}/bin/${program-prefix}gcc
        	export CXX_FOR_TARGET=${gcc-stage1}/bin/${program-prefix}c++
        	export AR_FOR_TARGET=${binutils}/bin/${program-prefix}ar
        	export AS_FOR_TARGET=${binutils}/bin/${program-prefix}as
        	export LD_FOR_TARGET=${binutils}/bin/${program-prefix}ld
        	export NM_FOR_TARGET=${binutils}/bin/${program-prefix}nm
        	export OBJDUMP_FOR_TARGET=${binutils}/bin/${program-prefix}objdump
        	export RANLIB_FOR_TARGET=${binutils}/bin/${program-prefix}ranlib
        	export STRIP_FOR_TARGET=${binutils}/bin/${program-prefix}strip
        	export READELF_FOR_TARGET=${binutils}/bin/${program-prefix}readelf
      '';
      configureFlags = [
        "--target=${target}"
      ];
    }
  );

  gcc = gccStdenv.mkDerivation (
    configCommon
    // {
      pname = "gcc-${target}";
      version = "11.3.0";
      src = gccSrc;
      buildInputs = configCommon.buildInputs ++ [
        binutils
        newlib
      ];
      nativeBuildInputs = configCommon.nativeBuildInputs ++ [
        binutils
        newlib
      ];
      configureFlags = gccConfigureFlags ++ [
        "--with-sysroot=${newlib}/${target}"
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
      meta = with lib; {
        description = "GNU Compiler Collection for ${target}";
        homepage = "https://gcc.gnu.org";
        license = licenses.gpl3Plus;
        maintainers = [ "billow" ];
        platforms = platforms.unix;
        mainProgram = "${program-prefix}gcc";
      };
    }
  );
in
symlinkJoin {
  name = "gcc-toolchain-${target}";
  paths = [
    binutils
    gcc
    newlib
  ];

  passthru = {
    inherit
      gcc
      binutils
      newlib
      binutils-mcs-elf
      ;
  };
}
