# Repository Guidelines

## Project Structure & Module Organization
- Root files: `flake.nix` (outputs and dev shells) and `flake.lock` (pinned inputs).
- This flake packages a TriCore-enabled GCC (`packages.default`)
- Upstream GCC sources are fetched from GitHub during the build; no local source tree lives here.

## Build, Test, and Development Commands
- Build default package: `nix build` or `nix build .#default`.
- Enter dev shell: `nix develop` (inherits flags and tools needed to work on the package).
- Inspect outputs: `nix flake show`.
- Update inputs: `nix flake update` (then commit changes to `flake.lock`).

## Coding Style & Naming Conventions
- Nix files: 2‑space indentation, trailing commas, and concise attribute names.
- Attribute sets follow Nixpkgs patterns (e.g., `packages`, `outputs`).
- Prefer lowerCamelCase for attribute keys and snake_case for local variables.
- Format before committing with either `nixfmt`.

## Testing Guidelines
- Primary validation is a successful derivation build: `nix build` on Linux and macOS.
- Optional checks: `nix flake check` if/when checks are added.
- When changing fetchers, verify the produced toolchain runs basic commands (e.g., `result/bin/tricore-gcc --version`).

## Commit & Pull Request Guidelines
- Commits: imperative mood, concise scope (e.g., "update gcc source", "fix build flags").
- Group related edits; avoid mixing refactors with functional changes.
- PRs: include a clear summary, rationale, and build logs (`nix build` output). Link related issues. If hashes changed, note the new `sha256`.

## Security & Configuration Tips
- Replace `lib.fakeHash` with the real `sha256` after the first build (copy the suggested hash from the Nix error and re-run).
- Inputs are pinned via `flake.lock`; propose updates in dedicated PRs and test on at least one Linux and one macOS system.
