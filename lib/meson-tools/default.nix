{
  lib,
  stdenvNoCC,
  meson,
  git,
  cacert,
  makeSetupHook,
}:
rec {
  fetchDeps =
    {
      pname,
      src ? null,
      sha256 ? "",
      ...
    }@args:
    stdenvNoCC.mkDerivation (
      args
      // {
        name = "${pname}-meson-deps";
        buildPhase = ''
          runHook preBuild

          deps=subprojects
          echo "Installing meson dependencies to $(realpath $deps)"
          meson $deps download
          find $deps -type d -name ".git" -prune -exec rm -rf {} +
          cp -r $deps $out/

          runHook postBuild
        '';

        nativeBuildInputs = [
          meson
          git
          cacert
        ];

        impureEnvVars = lib.fetchers.proxyImpureEnvVars;
        phases = [
          "unpackPhase"
          "buildPhase"
        ];
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = if sha256 == "" then lib.fakeSha256 else sha256;
      }
    );

  configHook = makeSetupHook {
    name = "meson-deps-config-hook";
  } ./meson-deps-config-hook.sh;

}
