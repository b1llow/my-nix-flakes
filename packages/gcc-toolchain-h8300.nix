{
  gccStdenv,
  fetchurl,
  lib,
  symlinkJoin,

  texinfo,
  gmp,
  mpfr,
  libmpc,
  zlib,
  zstd,
  isl,
  flex,
  bison,
}:
let
  target = "h8300-elf";
  binutils = gccStdenv.mkDerivation rec {
    pname = "binutils-${target}";
    version = "2.44";
    src = fetchurl {
      url = "https://sourceware.org/pub/binutils/releases/binutils-${version}.tar.xz";
      sha256 = "sha256-ziAX4FnWPmfduSQOnU7EnCiTYFA1zWDpKtUxd/Q3cjc=";
    };
    buildInputs = [
      flex
      bison
    ];
    nativeBuildInputs = [ ];
    configureFlags = [
      "--target=${target}"
      "--disable-nls"
      "--disable-werror"
    ];
  };
  newlib = gccStdenv.mkDerivation rec {
    pname = "newlib-${target}";
    version = "4.5.0.20241231";
    src = fetchurl {
      url = "https://sourceware.org/pub/newlib/newlib-${version}.tar.gz";
      sha256 = "sha256-M/EmBeAFSWWZbCXBOCs+RjsK+ReZAB9buMBjDy7IyFI=";
    };
    buildInputs = [
      binutils
      gcc-stage1
      isl
      libmpc
      gmp
      mpfr
      flex
      bison
    ];
    nativeBuildInputs = [
      binutils
      gcc-stage1
    ];
    configureFlags = [
      "--target=${target}"
      "--disable-nls"
    ];
  };

  gcc-stage1 = gccStdenv.mkDerivation rec {
    pname = "gcc-${target}-stage1";
    version = "14.3.0";
    src = fetchurl {
      url = "https://sourceware.org/pub/gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
      sha256 = "sha256-4Nx3KXYlYxrI5Q+pL//v6Jmk63AlktpcMu8E4ik6yjo=";
    };
    hardeningDisable = [
      "format"
      "pie"
      "stackclashprotection"
    ];
    nativeBuildInputs = [ binutils ];
    buildInputs = [
      binutils
      texinfo
      gmp
      mpfr
      libmpc
      zlib
      isl
      zstd
    ];
    preConfigure = ''
      mkdir build && cd build
    '';
    configureScript = ''
      ../configure
    '';
    configureFlags = [
      "--target=${target}"
      "--enable-languages=c"
      "--with-headers=yes"
      "--with-newlib=yes"
      "--enable-c99"
      "--disable-nls"
      "--disable-shared"
      "--disable-threads"
      "--disable-libssp"
      "--disable-libquadmath"
      "--disable-libstdcxx-pch"
      "--disable-test-suite"
      "--disable-lto"
      "--with-as=${binutils}/bin/${target}-as"
      "--with-ld=${binutils}/bin/${target}-ld"
    ];
    makeFlags = [
      "all-gcc"
    ];
    installTargets = "install-gcc";
  };
  gcc = gcc-stage1.overrideAttrs (old: {
    pname = "gcc-${target}";
    buildInputs = old.buildInputs ++ [
      newlib
    ];
    nativeBuildInputs = old.nativeBuildInputs ++ [
      newlib
    ];
    configureFlags = old.configureFlags ++ [
      "--with-sysroot=${newlib}/${target}"
      "--with-native-system-header-dir=/include"
    ];
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
      mainProgram = "${target}-gcc";
    };
  });
  gcc-toolchain = symlinkJoin {
    name = "${target}-toolchain";
    paths = [
      binutils
      newlib
      gcc
    ];
  };
in

{
  inherit
    binutils
    newlib
    gcc
    gcc-toolchain
    ;
}
