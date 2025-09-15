{
  description = "billow's nix flake packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        inherit (pkgs) callPackage nixfmt-tree;

        mesonTools = callPackage ./lib/meson-tools { };

        rizin = callPackage ./packages/rizin.nix { inherit mesonTools; };
        qemu-bap = callPackage ./packages/qemu-bap.nix {
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
