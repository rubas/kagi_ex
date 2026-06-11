# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project follows Semantic Versioning.

## [Unreleased]

### Fixed

- Search results keep Kagi's ranking: grouped and standard rows are parsed in
  one document-order pass, so `:limit` no longer drops grouped results that
  Kagi ranks near the top.
- Search queries that are not strings or lists of strings (charlists, keyword
  lists) return `:invalid_option` instead of being mangled or raising.
- `CloakedReq` adapter options (`:impersonate`, `:cookie_jar`, ...) passed via
  `:req_options` no longer raise `ArgumentError`; the adapter is attached
  before the configured options are merged.

### Changed

- Challenge detection runs only when a page has no recognizable results and no
  longer downcases the whole HTML body on the happy path.
- Requests no longer follow redirects, so the session cookie cannot travel to
  another host. Re-enable with `redirect: true` in `:req_options`. The
  endpoint URL and method are pinned after configuration merging, so
  `:req_options` can never point a request at another host.
- Requests no longer retry transient HTTP errors behind the caller's back; a
  429 returns `:rate_limited` after a single attempt. Re-enable with
  `retry: :safe_transient` in `:req_options`.
- Transport failures now include the adapter's failure reason (timeout, DNS,
  TLS, ...) in the `:request_failed` error message.
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
