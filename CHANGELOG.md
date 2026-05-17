# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [0.1.0] - 17.05.2026

### Added

- Typed `Kagi.search/2`, `Kagi.search/3`, `Kagi.summarize/2`, and `Kagi.summarize/3` APIs.
- Reusable `%Kagi.Client{}` with configurable session token resolution.
- `Req` transport by default and explicit `CloakedReq` transport support.
- Search result and summarizer stream parsers ported from the Rust `kagi` CLI.
- Release, CI, and package documentation matching the companion Elixir libraries.
