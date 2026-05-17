# kagi_ex

`kagi_ex` is a typed Elixir client for Kagi Search, Summarizer, and Maps.

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

`:transport`, `:req_options`, and `:cloaked_req_options` are configured via application config only. Browser impersonation is an environment-wide decision: once Kagi has flagged your IP, every subsequent request needs the same transport, headers, and TLS fingerprint to recover, so the choice belongs in `config.exs` and not at the call site.

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

## Maps

```elixir
{:ok, output} =
  Kagi.maps(client, "coffee zurich",
    ll: "47.3769,8.5417",
    zoom: 13,
    sort: :rating
  )

Enum.map(output.results, & &1.name)
```

`Kagi.maps/2` and `Kagi.maps/3` accept:

- `:limit` - maximum result count (default `10`)
- `:ll` - center coordinate as `"LAT,LON"`
- `:bbox` - bounding box as `"WEST,SOUTH,EAST,NORTH"`
- `:zoom` - zoom level (number)
- `:sort` - `:relevance`, `:rating`, `:distance`, or `:price`
- `:order` - `:asc` or `:desc`; defaults are `:desc` for `:rating`, `:asc` for `:distance` and `:price`

Sorting and the limit apply client-side to the parsed response.

## Returned Types

Search returns `{:ok, %Kagi.Search{results: [...], related: [...]}}`, where
each result is a `%Kagi.SearchResult{url: ..., title: ..., snippet: ...}`.

Summarizer returns `{:ok, %Kagi.Summary{summary: markdown}}`.

Maps returns `{:ok, %Kagi.Maps{results: [%Kagi.MapsResult{}]}}`. Each
`Kagi.MapsResult` carries `name`, `address`, `coordinates`
(`%Kagi.MapsResult.Coordinates{latitude:, longitude:}`), plus optional `phone`,
`url`, `source`, `id`, `rating`, `review_count`, `price`, `distance`,
`hours_now`, `types`, `links`, and `images`.

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
