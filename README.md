# kagi_ex

`kagi_ex` is a typed Elixir client for Kagi Search, Summarizer, and Maps.

Docs: <https://hexdocs.pm/kagi_ex>

It builds `Req` requests and sends them through
[`cloaked_req`](https://hexdocs.pm/cloaked_req).

## Installation

```elixir
def deps do
  [
    {:kagi_ex, "~> 0.1.0"}
  ]
end
```

## Authentication

Kagi requires a session token. Put it in application config:

```elixir
config :kagi_ex,
  session_token: System.fetch_env!("KAGI_SESSION_TOKEN")
```

The library never stores session tokens.

## Usage

Configure the client once:

```elixir
# config/runtime.exs
config :kagi_ex,
  session_token: System.fetch_env!("KAGI_SESSION_TOKEN")
```

Then call `kagi_ex`:

```elixir
{:ok, results} =
  Kagi.search("elixir req http client",
    lens: :programming,
    limit: 5
  )

Enum.map(results.results, & &1.url)
```

## Configuration

Set `:req_options` in application config when you need to override the default
`Req` request options.

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
  Kagi.maps("coffee zurich",
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
