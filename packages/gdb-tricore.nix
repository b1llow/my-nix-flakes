{
  bison,
  flex,
  autoconf269,
  automake,
  libtool,
  pkg-config,
  python311,
  expect,
  which,
  gawk,
  texinfo,
  autoreconfHook,
  readline70,
  ncurses,
  zlib,
  expat,
  dejagnu,
  zstd,
  gmp,
  mpfr,
  libmpc,
  isl,
  libiconv,

  fetchFromGitHub,
  lib,
  gccStdenv,
  ...
}:
let
  target = "tricore-elf";
in
gccStdenv.mkDerivation rec {
  pname = "gdb-tricore";
  version = "10.0.50";
  src = fetchFromGitHub {
    owner = "Starforge-Atelier";
    repo = "gdb-tricore";
    rev = "refs/heads/main";
    sha256 = "sha256-ciHqf6XoWHphRSoOkAG1roNqTTx4xsDeAUmv0Bfzj1k=";
  };

  nativeBuildInputs = [
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
  ];
  buildInputs = [
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
  ++ lib.optionals gccStdenv.isDarwin [ libiconv ];
  CFLAGS = "-Wno-error -Wno-error=incompatible-pointer-types";
  CXXFLAGS = "${CFLAGS}";

  preConfigure = ''
    export AUTOCONF=${autoconf269}/bin/autoconf
    echo "Using $(autoconf --version)"
    mkdir build
    cd build
  '';
  configureScript = "../configure";
  configureFlags = [
    "--prefix=${placeholder "out"}"
    "--enable-gdb"
    "--disable-binutils"
    "--disable-werror"
    "--with-python=${python311}"
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
    mainProgram = "${target}-gdb";
  };
}
