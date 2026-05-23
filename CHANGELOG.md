# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [0.1.1] - 23.05.2026

### Changed

- Update `cloaked_req` to `~> 0.4.0`, which runs native HTTP requests on the shared Tokio runtime, aborts in-flight requests when the caller exits, and honours Req `connect_options` for proxy configuration.

## [0.1.0] - 17.05.2026

### Added

- Typed `Kagi.search/2`, `Kagi.search/3`, `Kagi.summarize/2`, and `Kagi.summarize/3` APIs.
- Typed `Kagi.maps/2` and `Kagi.maps/3` API with `%Kagi.Maps{}`, `%Kagi.MapsResult{}`, and `%Kagi.MapsResult.Coordinates{}` structs.
- Client-side maps sorting by `:relevance`, `:rating`, `:distance`, or `:price` with sensible default orders.
- Reusable `%Kagi.Client{}` with configurable session token resolution.
- `Req` transport by default and explicit `CloakedReq` transport support.
- Search, summarizer, and maps parsers ported from the Rust `kagi` CLI.
- Release, CI, and package documentation matching the companion Elixir libraries.
