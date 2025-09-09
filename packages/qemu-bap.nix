{
  ocaml414,
  qemu,
  meson,
  protobufc,
  fetchFromGitHub,
  lib,
  stdenv,
  ...
}:
let
  qemuBase = qemu.override {
    enableDocs = false;
  };
in
qemuBase.overrideAttrs (old: rec {
  version = "10.0.2+bap";
  src = fetchFromGitHub {
    owner = "Starforge-Atelier";
    repo = "qemu";
    rev = "refs/heads/trace-10-tricore";
    sha256 = "sha256-k/IKmU3qIUcXqWLNVc73f6iB1hv9Gb/eMKstn/UkUzU=";
    fetchSubmodules = true;
    postFetch = ''
      cd "$out"
      for prj in subprojects/*.wrap; do
        ${lib.getExe meson} subprojects download "$(basename "$prj" .wrap)"
      done
      find subprojects -type d -name .git -prune -execdir rm -r {} +
    '';
  };

  configureFlags = [
    "--enable-debug"
    "--enable-asan"
    "--without-default-features"
    "--target-list=tricore-softmmu"
    "--enable-plugins"
    "--enable-user"
    "--enable-system"
    "--disable-docs"
  ];

  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
    ocaml414.piqi
  ];
  buildInputs = (old.buildInputs or [ ]) ++ [
    protobufc
  ];

  postInstall =
    let
      libExt = stdenv.hostPlatform.extensions.sharedLibrary;
    in
    "
            mkdir -p $out/plugins
            cp ./contrib/plugins/*${libExt} $out/plugins/
            cp ./contrib/plugins/bap-tracing/*${libExt} $out/plugins/
          ";

  meta = old.meta // {
    homepage = "https://github.com/BinaryAnalysisPlatform/qemu";
    # mainProgram = "qemu-system-tricore";
    # maintainers = oldAttrs.meta.maintainers ++ [ lib.maintainers.sfrijters ];
  };
})
