{
  rizin,
  meson,
  git,
  openssl,
  lib,
  fetchFromGitHub,
  mesonTools,
  ...
}:
let
  inherit (builtins) filter baseNameOf;

  src = fetchFromGitHub {
    owner = "rizinorg";
    repo = "rizin";
    rev = "976671d660fdce620ca84ecc99533dba237df9af";
    sha256 = "sha256-45HD6dYh2ptyzH3A/tVzp/3Pe/qcI38ylPkWB3WMu7A=";
  };
  mesonDeps = mesonTools.fetchDeps {
    pname = "rizin";
    inherit src;
    sha256 = "sha256-an6WMUZuBZf0d6rx/DwNTt8JZdYnYlnK/hD5sA5XB50=";
  };
in
rizin.overrideAttrs (old: {
  pname = "rizin";
  version = "0.9.0-dev";
  inherit src;
  patches = filter (x: baseNameOf x != "0001-fix-compilation-with-clang.patch") old.patches;

  mesonFlags = [ "-Dportable=true" ];

  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
    mesonTools.configHook
  ];
  buildInputs = [ ];

  inherit mesonDeps;

  meta = with lib; {
    description = "Rizin - Reverse Engineering Framework";
    license = licenses.lgpl3;
    platforms = platforms.unix;
  };
})
