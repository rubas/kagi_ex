# kagi_ex

The README describes the client, its options, and how it authenticates. It ships on Hex.

## Checks

- `task test:live` sends real requests to Kagi. It needs `KAGI_SESSION_TOKEN` and a Kagi account, so a human runs it,
  and only after a change to request building or response parsing.

## Layout

- `lib/kagi.ex` is the public API. `search`, `summarize`, and `maps` each have a bang variant and an arity that takes a
  `Kagi.Client`.
- `lib/kagi/http.ex` is the only module that sends a request. `search.ex`, `summary.ex`, and `maps.ex` build params and
  parse bodies.
- `test/fixtures/` holds recorded Kagi responses. The parser tests read them, so a new parse case needs a new fixture.

## Rules

- `:req_options` is the only general `Req` setting a caller gets. Do not add a public option for something `Req`
  already has. The one per-call exception is the `:timeout` of `Kagi.summarize`, which maps to `receive_timeout` and
  defaults to 60 seconds because the summarizer is slow.
- `Kagi.HTTP.get/3` defaults to `redirect: false, retry: false` and merges the URL and method last, after
  `:req_options`. Keep that order, so no configuration can send the session cookie to another host.
- Every function has a `@spec`, private ones included.
- Keep the session token out of every output. `Kagi.Client` derives `Inspect` without it. Never log it and never put it
  in a `Kagi.Error` message.
- A public function without a bang returns `{:ok, struct}` or `{:error, %Kagi.Error{}}`. The bang variants (`new!`,
  `search!`, `summarize!`, `maps!`) return the struct or raise. Add a new reason to `Kagi.Error` before you return it.

## Pitfalls

- Kagi answers a blocked request with HTTP 200 and a challenge page, so a 2xx status proves nothing. `Kagi.Search`
  looks for result markup first and returns `:blocked` for a CAPTCHA page.
- Search parses kagi.com class names (`.__sri_title_link`, `.__srgi-title a`, `.__sri-desc`). A new `:parse_error`
  means Kagi changed its markup, not that the caller sent a bad query. Fix the selector and record a new fixture.
- A merge to `main` that bumps `@version` in `mix.exs` creates the `vX.Y.Z` tag and the GitHub release. It does not
  publish to Hex; `mix hex.publish` stays a manual step after the GitHub release exists. Bump the version in a release
  PR with the CHANGELOG entry, never inside another change. [RELEASE.md](RELEASE.md) has the steps.
