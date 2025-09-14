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
    rev = "refs/heads/dev";
    sha256 = "sha256-qkkl0mIT056eirDKMUi9CR0dX1iTI+Uu+M86ueDO3P0=";
  };
  mesonDeps = mesonTools.fetchDeps {
    pname = "rizin";
    inherit src;
    sha256 = "sha256-BzaDCuKfwkKCkif1N3Nu0iCgk2yUfI2X3jvZc4BNULw=";
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
