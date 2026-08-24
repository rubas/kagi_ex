# kagi_ex Agent Instructions

`kagi_ex` is a typed Elixir client for Kagi Search and Summarizer.

## Development

- Keep public API documentation and typespecs in sync with code changes.
- Build requests with `Req` and send them through `CloakedReq`.
- Keep HTTP configuration limited to `:req_options` unless a new public contract
  is explicitly needed.
- Do not store or log Kagi session tokens.
- Tests should use fixtures or local test infrastructure by default; live Kagi requests must be opt-in.

## Quality Gates

- Run `mix format --check-formatted --dry-run`.
- Run `mix test`.
- Run `mix credo --strict` when Credo is available.
- Run `mix dialyzer` before release changes.
