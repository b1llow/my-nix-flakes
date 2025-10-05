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
        inherit (pkgs) callPackage lib nixfmt-tree;

        mesonTools = callPackage ./lib/meson-tools { };

        rizin = callPackage ./packages/rizin.nix { inherit mesonTools; };
        rizinp = rizin.withPlugins (rp: [
          rp.jsdec
          rp.rz-ghidra
          rp.sigdb
        ]);

        qemu-bap = callPackage ./packages/qemu-bap.nix {
          inherit mesonTools;
        };
        binutils-h8500 = callPackage ./packages/binutils-h8500.nix { };
        gdb-tricore = callPackage ./packages/gdb-tricore.nix { };

        gcc-toolchain-tricore-elf = callPackage ./packages/gcc-toolchain-tricore.nix { };
        gcc-toolchain-h8300-elf = callPackage ./packages/gcc-toolchain-h8300.nix { };
      in
      {
        packages = ({
          inherit
            rizin
            rizinp
            qemu-bap
            gdb-tricore
            binutils-h8500
            gcc-toolchain-tricore-elf
            gcc-toolchain-h8300-elf
            ;
        });

        apps = {
          qemu-system-tricore = {
            type = "app";
            program = "${qemu-bap}/bin/qemu-system-tricore";
          };
        };

        lib = {
          inherit mesonTools;
        };

        formatter = nixfmt-tree;

        devShells = {
          default = pkgs.mkShell { };
          ocaml = pkgs.mkShell {
            packages = [ ];
            buildInputs = (
              (with pkgs.ocamlPackages; [
                ocaml
                dune_3
                utop
                ocaml-lsp
                ocamlformat
                ounit
                base
                batteries
                #              domainslib
                zarith
              ])
              ++ [ pkgs.opam ]
            );
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
