{
  rizin,
  meson,
  git,
  openssl,
  autoPatchelfHook,
  cctools,
  lib,
  fetchFromGitHub,
  mesonTools,
  rev ? "deeaa15c902e18b9f40ccd38345a74546e2cd48e",
  sha256 ? "sha256-TS2B4gRHbr19ZadN1jUvTxY+o3kOW1916NZ8zbwrjxg=",
  mesonDepsSha256 ? "sha256-G8YMGFGsja/g/Tioicp9JF8Xcf/az+J/F56APwYEIag=",
  debug ? true,
  ...
}:
let
  inherit (builtins) filter baseNameOf;

  src = fetchFromGitHub {
    owner = "rizinorg";
    repo = "rizin";
    inherit rev sha256;
  };
  mesonDeps = mesonTools.fetchDeps {
    pname = "rizin";
    inherit src;
    sha256 = mesonDepsSha256;
  };
  usePlugins = (
    rz:
    (lib.mapAttrs (
      name: prev:
      (prev.override { rizin = rz; }).overrideAttrs (prev': {
        postFixup = (prev'.postInstall or "") + ''
          set -euo pipefail

          plugdir="$out/lib/rizin/plugins"
          stdlib="$out/lib"
          mkdir -p "$stdlib"

          cd $plugdir
          for l in *.dylib; do
            ln -s "$plugdir/$l" "$stdlib/$l"
          done
        '';
      })
    ) (lib.filterAttrs (k: v: k != "sigdb") rizin.plugins))
    // {
      sigdb = rizin.plugins.sigdb;
    }
  );
  rizin' = (
    rizin.overrideAttrs (old: {
      pname = "rizin";
      version = "0.9.0.${src.rev}";
      inherit src mesonDeps;
      patches = filter (x: baseNameOf x != "0001-fix-compilation-with-clang.patch") old.patches;

      separateDebugInfo = debug;
      mesonBuildType = if debug then "debugoptimized" else "release";
      CFLAGS = (old.CFLAGS or [ ]) ++ (lib.optionals debug [ "-g" ]);

      mesonFlags = [ "-Dportable=true" ];
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        mesonTools.configHook
      ];
      buildInputs = [ ];

      passthru = rec {
        plugins = usePlugins rizin';
        withPlugins =
          filter:
          ((rizin.withPlugins filter).override {
            rizin = rizin';
            plugins = filter plugins;
          });
      };
    })
  );
in
rizin'
