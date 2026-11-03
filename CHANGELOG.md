# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-11-03

### Added

- `Xmlb`, defined from the `Xmlb-2.0.typelib` GObject Introspection typelib at require
  time, giving libxmlb, querying the binary XML blobs AppStream metadata is compiled into. The typelib version is `2.0`, read off the package.
- A dev shell pinning the library and its typelib from one nixpkgs, and CI that
  runs the suite inside it.

  The typelib is in the package's `lib` output, not its default one -- `pkgs.libxmlb.lib`.
