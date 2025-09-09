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

        rizin = pkgs.callPackage ./packages/rizin.nix { };
        qemu-bap = pkgs.callPackage ./packages/qemu-bap.nix {
          ocaml414 = (pkgs.ocaml-ng.ocamlPackages_4_14 or pkgs.ocamlPackages_4_14);
        };
        gdb-tricore = pkgs.callPackage ./packages/gdb-tricore.nix { };
        gcc-toolchain-tricore = pkgs.callPackage ./packages/gcc-toolchain-tricore.nix { };
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
      }
    );
}
