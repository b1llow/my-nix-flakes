{
  bison,
  flex,
  texinfo,
  gmp,
  mpfr,
  gccStdenv,
  fetchurl,
  lib,
}:
gccStdenv.mkDerivation rec {
  pname = "gcc";
  version = "2.95.3";
  src = fetchurl {
    url = "https://sourceware.org/pub/gcc/releases/gcc-${version}/gcc-${version}.tar.bz2";
    sha256 = "sha256-z5GmtPQSSIlfBrzQVwpi0kF+6Z0y5uLF9wSQ4Otq9eQ=";
  };

  nativeBuildInputs = [
    bison
    flex
    texinfo
    gmp
    mpfr
  ];
  preConfigure = ''
    mkdir build && cd build
  '';
  configureScript = ''
    env ac_cv_prog_cc_g=no ac_cv_exeext="" ../configure
  '';
  configureFlags = [
    "--target=h8500-hms"
    "--program-prefix=h8500-hms-"
    "--disable-nls"
    "--disable-werror"
    "--enable-languages=c,c++"
    #"--with-sysroot=${newlib-tricore-elf}/${target-name}"
    "--with-native-system-header-dir=/include"
  ];

  enableParallelBuilding = true;
  # dontUpdateAutotoolsGnuConfigScripts = true;
  doCheck = false;
  # must add
  CFLAGS = "-std=gnu89 -fcommon -Wno-error -Wno-error=implicit-function-declaration";
  CXXFLAGS = "${CFLAGS}";
  hardeningDisable = [ "format" ];
  makeFlags = [
    "INFO_DEPS="
    "MAKEINFO="
    "all-gcc"
    "all-target-libgcc"
  ];
  installTargets = "install-gcc install-target-libgcc";

  meta = with lib; {
    description = "GNU gcc with h8500-hms target (H8/500)";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
  };
}
