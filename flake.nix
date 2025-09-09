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
        rizin = pkgs.callPackage ./packages/rizin.nix { };
      in
      {
        packages = {
          inherit rizin;
        };
      }
    );
}
