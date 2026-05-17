# kagi_ex Agent Instructions

`kagi_ex` is a typed Elixir client for Kagi Search and Summarizer.

## Development

- Keep public API documentation and typespecs in sync with code changes.
- Preserve `Req` as the default transport.
- Keep `CloakedReq` support explicit via `transport: :cloaked_req`.
- Do not store or log Kagi session tokens.
- Tests should use fixtures or local test infrastructure by default; live Kagi requests must be opt-in.

## Quality Gates

- Run `mix format --check-formatted --dry-run`.
- Run `mix test`.
- Run `mix credo --strict` when Credo is available.
- Run `mix dialyzer` before release changes.

<!-- usage-rules-start -->
<!-- cloaked_req-start -->
## cloaked_req usage
_Req adapter around Rust wreq with browser impersonation support_

[cloaked_req usage rules](deps/cloaked_req/usage-rules.md)
<!-- cloaked_req-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A config-driven dev tool for Elixir projects to manage AGENTS.md files and agent skills from dependencies_

[usage_rules usage rules](deps/usage_rules/usage-rules.md)
<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
[usage_rules:elixir usage rules](deps/usage_rules/usage-rules/elixir.md)
<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
[usage_rules:otp usage rules](deps/usage_rules/usage-rules/otp.md)
<!-- usage_rules:otp-end -->
<!-- usage-rules-end -->
