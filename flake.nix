{
  description = "billow's nix flake packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlay = {
      url = "github:nix-ocaml/nix-overlays";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ocaml-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ocaml-overlay.overlays.default ];
        };
        inherit (pkgs) callPackage nixfmt-tree;

        mesonTools = callPackage ./lib/meson-tools { };

        rizin = callPackage ./packages/rizin.nix { inherit mesonTools; };
        qemu-bap = callPackage ./packages/qemu-bap.nix {
          ocaml414 = (pkgs.ocaml-ng.ocamlPackages_4_14 or pkgs.ocamlPackages_4_14);
          inherit mesonTools;
        };
        gdb-tricore = callPackage ./packages/gdb-tricore.nix { };
        gcc-toolchain-tricore = callPackage ./packages/gcc-toolchain-tricore.nix { };

      in
      {
        packages = {
          inherit rizin qemu-bap gdb-tricore;
          inherit (gcc-toolchain-tricore)
            binutils-mcs-elf
            binutils-tricore-elf
            newlib-tricore-elf
            gcc-tricore-elf
            gcc-toolchain-tricore
            ;
        };

        apps = {
          rizin = {
            type = "app";
            program = "${rizin}/bin/rizin";
          };
          qemu-system-tricore = {
            type = "app";
            program = "${qemu-bap}/bin/qemu-system-tricore";
          };
          tricore-elf-gdb = {
            type = "app";
            program = "${gdb-tricore}/bin/tricore-elf-gdb";
          };
          tricore-elf-gcc = {
            type = "app";
            program = "${gcc-toolchain-tricore.gcc-tricore-elf}/bin/tricore-elf-gcc";
          };
        };

        lib = {
          inherit mesonTools;
        };

        formatter = nixfmt-tree;
      }
    );
}
