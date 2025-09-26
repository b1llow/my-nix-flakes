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
gccStdenv.mkDerivation {
  pname = "binutils";
  version = "2.16.1a-h8500";
  src = fetchurl {
    url = "https://sourceware.org/pub/binutils/releases/binutils-2.16.1a.tar.bz2";
    sha256 = "sha256-14pv+YKrL3NyFwbnv9MoWsZHgEZk5+pHhuZtAfkcVsU=";
  };

  nativeBuildInputs = [
    bison
    flex
    texinfo
    gmp
    mpfr
  ];
  # must add
  configureScript = ''
    env ac_cv_prog_cc_g=no ac_cv_exeext="" ./configure
  '';
  configureFlags = [
    "--target=h8500-hms"
    "--program-prefix=h8500-hms-"
    "--disable-nls"
    "--disable-werror"
  ];

  enableParallelBuilding = true;
  dontUpdateAutotoolsGnuConfigScripts = true;
  doCheck = false;
  # must add
  NIX_CFLAGS_COMPILE = "-std=gnu89 -fcommon -Wno-error";
  hardeningDisable = [ "format" ];
  makeFlags = [
    "INFO_DEPS="
    "MAKEINFO="
  ];

  meta = with lib; {
    description = "GNU binutils 2.16.1 with h8500-hms target (H8/500)";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
  };
}
