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
      hash ? "",
      impureEnvVars ? [ ],
    }@args:
    let
      hash_ =
        if hash != "" then
          {
            outputHash = hash;
          }
        else
          {
            outputHash = "";
            outputHashAlgo = "sha256";
          };
    in
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

        impureEnvVars =
          lib.fetchers.proxyImpureEnvVars
          ++ impureEnvVars
          ++ [
            # This variable allows the user to pass additional options to curl
            "NIX_CURL_FLAGS"
          ];
        SSL_CERT_FILE =
          if
            (
              hash_.outputHash == ""
              || hash_.outputHash == lib.fakeSha256
              || hash_.outputHash == lib.fakeSha512
              || hash_.outputHash == lib.fakeHash
            )
          then
            "${cacert}/etc/ssl/certs/ca-bundle.crt"
          else
            "/no-cert-file.crt";

        phases = [
          "unpackPhase"
          "buildPhase"
        ];
        outputHashMode = "recursive";
      }
    );

  configHook = makeSetupHook {
    name = "meson-deps-config-hook";
  } ./meson-deps-config-hook.sh;

}
