{
  rizin,
  openssl,
  lib,
  ...
}:
let
  ver = "0.8.1";
  rizin-src = builtins.fetchurl {
    url = "https://github.com/rizinorg/rizin/releases/download/v${ver}/rizin-src-v${ver}.tar.xz";
    sha256 = "sha256:1hjf180q4ba0cs5ys7vwy5xs1k6195kransj8fn3dp6p4mjiwazg";
  };
in
rizin.overrideAttrs (old: {
  pname = "rizin";
  version = "${ver}";
  src = rizin-src;
  patches = builtins.filter (
    x: builtins.baseNameOf x != "0001-fix-compilation-with-clang.patch"
  ) old.patches;
  buildInputs = old.buildInputs ++ [ openssl.dev ];

  meta = with lib; {
    description = "Rizin - Reverse Engineering Framework";
    license = licenses.lgpl3;
    platforms = platforms.unix;
  };
})
