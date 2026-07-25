# kagi_ex

Typed Elixir client for Kagi Search, Summarizer, and Maps, published on Hex.
It does not call Kagi's documented APIs. It sends a browser session cookie to
the site's own endpoints and parses the response, so it needs no API token and
no API credit.

## Gates

- `task check` is the default gate: compile with warnings as errors, format
  check, Credo strict, Dialyzer, tests, and `mix deps.audit`.
- CI on a pull request runs compile, format check, Credo, Dialyzer, tests, and
  `zizmor` on the workflows. It leaves out `mix deps.audit`, which only a local
  `task check` runs. `security.yml` runs the audit daily and on a `main` push
  that touches `mix.exs` or `mix.lock`.
- `task fix` formats.
- `task test:live` sends real requests to Kagi. It needs `KAGI_SESSION_TOKEN`
  and a Kagi account, so a human runs it, and only after a change to request
  building or response parsing. `test/test_helper.exs` excludes the `:live`
  tag, which keeps CI off it.

## Layout

- `lib/kagi.ex` is the public API. Each of `search`, `summarize`, and `maps`
  has a bang variant and an arity that takes a `Kagi.Client`.
- `lib/kagi/http.ex` is the only module that sends a request. `search.ex`,
  `summary.ex`, and `maps.ex` build params and parse bodies.
- `test/fixtures/` holds recorded Kagi responses. Parser tests read them, so a
  new parse case needs a new fixture.

## House decisions

- `:req_options` is the only general `Req` knob a caller gets. Do not add a
  public option for something `Req` already exposes. The one per-call exception
  is `Kagi.summarize`'s `:timeout`, which maps to `receive_timeout` and falls
  back to 60 seconds because the summarizer answers slowly.
- `Kagi.HTTP.get/3` defaults to `redirect: false, retry: false` and merges the
  URL and method last, after `:req_options`. Keep that order: it stops any
  configuration from sending the session cookie to another host.
- Every function has a `@spec`, private ones included.
- The session token stays out of every output. `Kagi.Client` derives `Inspect`
  without it. Never log it and never put it in a `Kagi.Error` message.
- A non-bang public function returns `{:ok, struct}` or
  `{:error, %Kagi.Error{}}`. The bang variants (`new!`, `search!`, `summarize!`,
  `maps!`) return the struct or raise. Add a new reason to `Kagi.Error` before
  you return it.

## Pitfalls

- Kagi answers a blocked request with HTTP 200 and a challenge page, so a 2xx
  status alone proves nothing. `Kagi.Search` looks for result markup first and
  returns `:blocked` for a CAPTCHA page.
- Search parses kagi.com class names (`.__sri_title_link`, `.__srgi-title a`,
  `.__sri-desc`). A new `:parse_error` means Kagi changed its markup, not that
  the caller sent a bad query: fix the selector and record a fresh fixture.
- Maps applies `:sort`, `:order`, and `:limit` client-side to the parsed
  response. The endpoint ignores them.
- A pasted `Cookie` header returns `:invalid_session_token`. Only the
  `kagi_session` cookie value is a token.
- Bumping `@version` in `mix.exs` creates the `vX.Y.Z` tag and the GitHub
  release on merge to `main`. It does not publish to Hex; that stays a manual
  `mix hex.publish` after the GitHub release exists. Do the bump in a release
  PR together with the CHANGELOG entry, never inside another change.
  [RELEASE.md](RELEASE.md) holds the steps.
