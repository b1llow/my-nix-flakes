# Copilot Instructions for `my-nix-flakes`

## Overview
This repository is a collection of Nix Flakes for managing various packages and tools. The structure is modular, with each package defined in its own file under the `packages/` directory. Shared utilities and scripts are located in the `lib/` directory.

## Key Directories and Files

- **`flake.nix`**: The entry point for the Nix Flake. Defines the outputs and dependencies.
- **`flake.lock`**: Lock file for the Flake, ensuring reproducibility.
- **`packages/`**: Contains Nix expressions for individual packages. Examples include:
  - `gcc-toolchain-tricore.nix`: Configuration for the GCC toolchain targeting TriCore.
  - `gdb-tricore.nix`: Configuration for GDB targeting TriCore.
  - `qemu-bap.nix`: Configuration for QEMU with Binary Analysis Platform (BAP).
  - `rizin.nix`: Configuration for the Rizin reverse engineering framework.
- **`lib/`**: Contains shared scripts and utilities, such as:
  - `meson-tools/`: Utilities for working with Meson build system.
  - `meson-deps-config-hook.sh`: A shell script for configuring Meson dependencies.

## Developer Workflows

### Building Packages
To build a specific package, use the `nix build` command with the desired package name. For example:
```bash
nix build .#qemu-bap
```
This will build the `qemu-bap` package defined in `packages/qemu-bap.nix`.

### Testing
Currently, there is no explicit testing framework defined in the repository. However, you can validate by running the `nix flake check` command and ensuring the outputs are as expected.

### Debugging
For debugging build issues, use the `nix log` command to inspect build logs:
```bash
nix log /nix/store/<build-output-path>
```
Replace `<build-output-path>` with the actual path from the build output.

## Project-Specific Conventions

- **Modular Design**: Each package is defined in its own file under `packages/`.
- **Shared Utilities**: Common scripts and hooks are stored in `lib/`.
- **Flake Outputs**: The `flake.nix` file defines the outputs, which include packages and utilities.

## External Dependencies

- **Nix**: This project relies on the Nix package manager. Ensure you have Nix installed and configured to use Flakes.

## Examples

### Adding a New Package
To add a new package:
1. Create a new `.nix` file in the `packages/` directory.
2. Define the package using Nix expressions.
3. Update `flake.nix` to include the new package in the outputs.

### Modifying Shared Utilities
If you need to update a shared script:
1. Edit the relevant file in `lib/`.
2. Test the changes by rebuilding the affected packages.

---

Feel free to update this document as the project evolves. If you encounter any unclear or incomplete sections, please provide feedback.