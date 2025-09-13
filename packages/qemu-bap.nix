{
  ocaml414,
  qemu,
  meson,
  protobufc,
  fetchFromGitHub,
  lib,
  stdenv,
  mesonTools,
  ...
}:
let
  qemuBase = qemu.override {
    enableDocs = false;
  };
  src = fetchFromGitHub {
    owner = "Starforge-Atelier";
    repo = "qemu";
    rev = "refs/heads/trace-10-tricore";
    sha256 = "sha256-hIuRM4HmE1H/TIpufEVru9uZLGyKnjcIor6YBn2DY3g=";
    fetchSubmodules = true;
  };
  mesonDeps = mesonTools.fetchDeps {
    pname = "qemu-bap";
    inherit src;
  };
in
qemuBase.overrideAttrs (old: rec {
  version = "10.0.2+bap";
  inherit src;
  inherit mesonDeps;

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
    mesonTools.configHook
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
