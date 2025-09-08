{
  description = "TriCore-enabled GCC 11.3.0 toolchain";

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
        pkgs = import nixpkgs { inherit system; };

        tricoreGccSrc = pkgs.fetchFromGitHub {
          owner = "Starforge-Atelier";
          repo = "tricore-gcc";
          rev = "refs/heads/main";
          sha256 = "sha256-8p73XCEOHZJyQI6mmRDMOh5/KPpaKQOfs6ibRZEnYPw=";
          fetchSubmodules = true;
        };

        tricoreBinutilsSrc = pkgs.fetchFromGitHub {
          owner = "Starforge-Atelier";
          repo = "tricore-binutils-gdb";
          rev = "refs/heads/master";
          sha256 = "sha256-5X+b5DB7tHldk70w+yswpuOXTgI+5w8P8wzRs4YKqAo=";
          fetchSubmodules = true;
        };

        tricoreNewlibSrc = pkgs.fetchFromGitHub {
          owner = "Starforge-Atelier";
          repo = "tricore-newlib-cygwin";
          rev = "refs/heads/master";
          sha256 = "sha256-Ct5+rApyvCbvnOwEBxU1mI8IlZp6eirt3Gxj9xRsxM8=";
          fetchSubmodules = true;
        };

        binutils = pkgs.binutils.overrideAttrs (old: {
          version = "2.42+tricore";
          src = tricoreBinutilsSrc;
          patches = [ ];
          configureFlags = (old.configureFlags or [ ]) ++ [
            "--target=tricore-elf"
            "--disable-nls"
            "--disable-werror"
          ];
        });

        gcc-unwrapped = pkgs.gcc-unwrapped.overrideAttrs (old: {
          version = "11.3.0-+tricore";
          src = tricoreGccSrc;
          patches = [ ];
          # 交叉环境下 nixpkgs 会自动加 --target=tricore-elf
          configureFlags = (old.configureFlags or [ ]) ++ [
            "--target=tricore-elf"
            "--enable-languages=c,c++"
            "--with-newlib"
            "--disable-nls"
            # 下面这些在 bare-metal 上常见地关掉，减少不必要组件
            "--disable-libssp"
            "--disable-libquadmath"
            "--disable-libsanitizer"
            # Darwin 上如遇 LTO/插件构建问题可再加：
            # "--disable-lto" "--disable-plugin"
          ];
        });

        newlib = pkgs.newlib.overrideAttrs (old: {
          version = "4.3.0+tricore";
          src = tricoreNewlibSrc;
          patches = [ ];
          configureFlags = (old.configureFlags or [ ]) ++ [
            "--target=tricore-elf"
            "--disable-newlib-supplied-syscalls"
            "--disable-nls"
          ];
        });

      in
      {
        packages.default = gcc-unwrapped;
        packages.binutils = binutils;
        packages.newlib = newlib;
      }
    );
}
