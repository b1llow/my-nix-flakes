{
  rizin,
  meson,
  git,
  openssl,
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  cacert,
  ...
}:
let
  fetchMesonDeps =
    {
      name ? "meson-deps",
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
        name = "${name}-meson-deps";
        buildPhase = ''
          runHook preBuild

          deps=subprojects
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

        dontUseMesonConfigure = true;
        dontUseMesonCheck = true;
        dontUseMesonInstall = true;
        outputHashMode = "recursive";
      }
    );
  rizinSrc = fetchFromGitHub {
    owner = "rizinorg";
    repo = "rizin";
    rev = "refs/heads/dev";
    sha256 = "sha256-qkkl0mIT056eirDKMUi9CR0dX1iTI+Uu+M86ueDO3P0=";
  };
  rizinDeps = fetchMesonDeps {
    name = "rizin";
    src = rizinSrc;
    hash = lib.fakeSha256;
  };
in
rizin.overrideAttrs (old: {
  pname = "rizin";
  version = "0.9.0-dev";
  src = rizinSrc;
  patches = builtins.filter (
    x: builtins.baseNameOf x != "0001-fix-compilation-with-clang.patch"
  ) old.patches;

  preConfigure = old.preConfigure + ''
    rm -rf subprojects
    ln -s ${rizinDeps} subprojects
  '';

  meta = with lib; {
    description = "Rizin - Reverse Engineering Framework";
    license = licenses.lgpl3;
    platforms = platforms.unix;
  };
})
