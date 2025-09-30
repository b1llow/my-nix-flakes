{
  description = "billow's nix flake packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    (flake-utils.lib.eachDefaultSystem (
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
        binutils-h8500 = callPackage ./packages/binutils-h8500.nix { };
        h8300-elf-toolchain = callPackage ./packages/gcc-toolchain-h8300.nix { };
      in
      {
        packages = {
          inherit
            rizin
            qemu-bap
            gdb-tricore
            binutils-h8500
            ;
          inherit (gcc-toolchain-tricore)
            binutils-mcs-elf
            binutils-tricore-elf
            newlib-tricore-elf
            gcc-tricore-elf
            gcc-toolchain-tricore
            ;
          h8300-elf-toolchain = h8300-elf-toolchain.gcc-toolchain;
          h8300-elf-gcc = h8300-elf-toolchain.gcc;
          h8300-elf-binutils = h8300-elf-toolchain.binutils;
          h8300-elf-newlib = h8300-elf-toolchain.newlib;
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

        devShells = {
          default = pkgs.mkShell {
          };
        };
      }
    ))
    // {
      templates = {
        rust = {
          path = ./templates/rust;
          description = "A Rust project template with Nix flake";
        };
      };
    };
}
