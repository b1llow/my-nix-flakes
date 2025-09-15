{
  qemu,
  meson,
  protobufc,
  ocaml-ng,
  fetchFromGitHub,
  lib,
  stdenv,
  mesonTools,
  ...
}:
let
  qemu' = qemu.override {
    pluginsSupport = true;
    enableDocs = false;
    guestAgentSupport = false;
    numaSupport = false;
    seccompSupport = false;
    alsaSupport = false;
    pulseSupport = false;
    pipewireSupport = false;
    sdlSupport = false;
    jackSupport = false;
    gtkSupport = false;
    vncSupport = false;
    smartcardSupport = false;
    spiceSupport = false;
    ncursesSupport = false;
    usbredirSupport = false;
    xenSupport = false;
    cephSupport = false;
    glusterfsSupport = false;
    openGLSupport = false;
    rutabagaSupport = false;
    virglSupport = false;
    libiscsiSupport = false;
    smbdSupport = false;
    tpmSupport = false;
    uringSupport = false;
    canokeySupport = false;
    capstoneSupport = false;
  };
  bap-frame = fetchFromGitHub {
    owner = "b1llow";
    repo = "bap-frames";
    rev = "refs/heads/tricore-support";
    sha256 = "sha256-1f65TEIXncDD6N54Ton/VsoNYBoxEr1h0P2HIOSzI+o=";
  };
  src = fetchFromGitHub {
    owner = "Starforge-Atelier";
    repo = "qemu";
    rev = "refs/heads/trace-10-tricore";
    sha256 = "sha256-4TCXZCUjDz9doCFkdm8iXghnuZ2c8w5PopzD7sKRusc=";
    fetchSubmodules = false;
  };
  mesonDeps = mesonTools.fetchDeps {
    pname = "qemu-bap";
    inherit src;
    sha256 = "sha256-xVR3XB7RpQ2eWgLBbBjGIzf4Bb5UCbg9Dn599ncLkPo=";
  };
in
qemu'.overrideAttrs (old: rec {
  version = "10.0.2+bap";
  inherit src;
  inherit mesonDeps;

  configureFlags = [
    "--without-default-features"
    "--target-list=tricore-softmmu"
    "--enable-debug"
    "--enable-asan"
    "--enable-user"
    "--enable-system"
    "--enable-plugins"
    "--disable-docs"
  ];

  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
    ocaml-ng.ocamlPackages_4_14.piqi
    mesonTools.configHook
  ];
  buildInputs = (old.buildInputs or [ ]) ++ [
    protobufc
  ];

  preConfigure = (old.preConfigure or "") + ''
    echo "Copying bap-frame into $(pwd)/contrib/plugins/bap-tracing/bap-frames"
    cp -r ${bap-frame}/* contrib/plugins/bap-tracing/bap-frames
  '';

  postInstall =
    let
      libExt = stdenv.hostPlatform.extensions.sharedLibrary;
    in
    ''
      mkdir -p $out/plugins
      cp ./contrib/plugins/*${libExt} $out/plugins/
      cp ./contrib/plugins/bap-tracing/*${libExt} $out/plugins/
    '';

  meta = old.meta // {
    homepage = "https://github.com/BinaryAnalysisPlatform/qemu";
  };
})
