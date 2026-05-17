# kagi_ex

`kagi_ex` is a typed Elixir client for Kagi Search and Summarizer.

Docs: <https://hexdocs.pm/kagi_ex>

It uses `Req` by default and can route requests through
[`cloaked_req`](https://hexdocs.pm/cloaked_req) when browser impersonation is
needed.

## Installation

```elixir
def deps do
  [
    {:kagi_ex, "~> 0.1.0"}
  ]
end
```

## Authentication

Kagi requires a session token. `kagi_ex` resolves it in this order:

1. `:session_token` option
2. `config :kagi_ex, :session_token, "..."`

The library never stores session tokens.

## Usage

Use the default `Req` transport:

```elixir
client = Kagi.new!(session_token: my_session_token())

{:ok, results} =
  Kagi.search(client, "elixir req http client",
    lens: :programming,
    limit: 5
  )

Enum.map(results.results, & &1.url)
```

## Configuration

`:transport`, `:req_options`, and `:cloaked_req_options` can be set per call or as application config. Per-call options always win.

Browser impersonation is normally an environment-wide decision, not a per-request one: once Kagi has flagged your IP, every subsequent request needs the same transport, headers, and TLS fingerprint to recover. Configuring `:cloaked_req` once in `config.exs` keeps the choice in one place and lets call sites stay focused on the query itself.

```elixir
# config/runtime.exs
config :kagi_ex,
  session_token: System.fetch_env!("KAGI_SESSION_TOKEN"),
  transport: :cloaked_req,
  cloaked_req_options: [impersonate: :chrome_136]
```

```elixir
# anywhere in the app
{:ok, results} = Kagi.search("elixir req http client", lens: :programming, limit: 5)
```

`cloaked_req` is an optional dependency; add `{:cloaked_req, "~> 0.3"}` to your deps when selecting the `:cloaked_req` transport.

Override per call when you need a different transport for one request:

```elixir
Kagi.new!(transport: :req)
```

## Search Options

`Kagi.search/2` and `Kagi.search/3` accept:

- `:limit` - maximum result count
- `:region` - region code such as `"ch"`, `"us"`, `"de"`, or `"no_region"`
- `:lens` - `:default`, `:programming`, `:forums`, `:pdfs`,
  `:non_commercial`, or `:world_news`
- `:sort` - `:recency`, `:website`, or `:ad_trackers`
- `:time` - `:day`, `:week`, `:month`, or `:year`
- `:from` / `:to` - `YYYY-MM-DD` date range; cannot be combined with `:time`
- `:site` - appends a `site:` filter
- `:filetype` - appends a `filetype:` filter
- `:verbatim` - disables query expansion when true

## Summarizer Options

`Kagi.summarize/2` and `Kagi.summarize/3` accept:

- `:type` - `:summary` or `:takeaway`
- `:lang` - target language code, default `"EN"`

## Returned Types

Search returns `{:ok, %Kagi.Search{results: [...], related: [...]}}`, where
each result is a `%Kagi.SearchResult{url: ..., title: ..., snippet: ...}`.

Summarizer returns `{:ok, %Kagi.Summary{summary: markdown}}`.

Failures return `{:error, %Kagi.Error{reason: reason, message: message}}`.

## Development Checks

Run deterministic local checks:

```bash
task check
```

Run opt-in live Kagi checks with a real session token:

```bash
export KAGI_SESSION_TOKEN="..."
task test:live
```
