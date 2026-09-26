# kagi_ex

`kagi_ex` is a typed Elixir client for Kagi Search, Summarizer, and Maps. It does not use Kagi's documented APIs. It
sends your browser session cookie to the endpoints that kagi.com itself uses, so it needs no API token and no API
credit.

Docs: <https://hexdocs.pm/kagi_ex>

It builds `Req` requests and sends them through [`cloaked_req`](https://hexdocs.pm/cloaked_req).

## Installation

```elixir
def deps do
  [
    {:kagi_ex, "~> 0.4.0"}
  ]
end
```

## Authentication

Kagi needs a session token. Log in at [kagi.com](https://kagi.com), open your browser's cookies for the site, and copy
the value of the `kagi_session` cookie. Copy only the value, not the whole `Cookie` header. Put it in the application
config:

```elixir
config :kagi_ex,
  session_token: System.fetch_env!("KAGI_SESSION_TOKEN")
```

A token with characters that a cookie value cannot hold, such as a pasted `key=value; other=...` header, returns
`{:error, %Kagi.Error{reason: :invalid_session_token}}`.

## Usage

```elixir
{:ok, results} =
  Kagi.search("elixir req http client",
    lens: :programming,
    limit: 5
  )

Enum.map(results.results, & &1.url)
```

Each call reads the application config and builds a client. To reuse a client, build it with `Kagi.new!/0` and pass it
as the first argument:

```elixir
client = Kagi.new!()

{:ok, results} = Kagi.search(client, "elixir req http client", limit: 5)
{:ok, summary} = Kagi.summarize(client, "https://elixir-lang.org")
```

Each function has a bang variant (`Kagi.search!`, `Kagi.summarize!`, `Kagi.maps!`) that raises `Kagi.Error` instead
of returning an error tuple.

## Configuration

Set `:req_options` in the application config to change the default `Req` options, including `CloakedReq` adapter
options such as `:impersonate`.

By default a request follows no redirect and does no retry. One call is one HTTP request, and the session cookie never
goes to another host. To turn them on, set `redirect: true` or `retry: :safe_transient` in `:req_options`.

## Search options

`Kagi.search/2` and `Kagi.search/3` accept:

- `:limit`: maximum number of results, default `10`. The client applies it.
- `:region`: a region code such as `"ch"`, `"us"`, `"de"`, or `"no_region"`.
- `:lens`: `:default`, `:programming`, `:forums`, `:pdfs`, `:non_commercial`, or `:world_news`.
- `:sort`: `:recency`, `:website`, or `:ad_trackers`.
- `:time`: `:day`, `:week`, `:month`, or `:year`.
- `:from` and `:to`: a `YYYY-MM-DD` date range. You cannot use them with `:time`.
- `:site`: adds a `site:` filter.
- `:filetype`: adds a `filetype:` filter.
- `:verbatim`: `true` turns off query expansion.

## Summarizer options

`Kagi.summarize/2` and `Kagi.summarize/3` accept:

- `:type`: `:summary` or `:takeaway`.
- `:lang`: target language code, default `"EN"`.
- `:timeout`: receive timeout in milliseconds. It limits the wait for the response headers and then each wait for the
  next body chunk; it is not a total deadline. The default is `req_options[:receive_timeout]` when set, else 60 seconds.

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

- `:limit`: maximum number of results, default `10`.
- `:ll`: center coordinate as `"LAT,LON"`.
- `:bbox`: bounding box as `"WEST,SOUTH,EAST,NORTH"`.
- `:zoom`: zoom level, a number.
- `:sort`: `:relevance`, `:rating`, `:distance`, or `:price`.
- `:order`: `:asc` or `:desc`. The default is `:desc` for `:rating` and `:asc` for `:distance` and `:price`.

The endpoint ignores sort, order, and limit, so the client applies them to the parsed response.

## Return values

Search returns `{:ok, %Kagi.Search{results: [...], related: [...]}}`. Each result is a
`%Kagi.SearchResult{url: ..., title: ..., snippet: ...}`.

Summarizer returns `{:ok, %Kagi.Summary{summary: markdown}}`.

Maps returns `{:ok, %Kagi.Maps{results: [%Kagi.MapsResult{}]}}`. Each `Kagi.MapsResult` has `name`, `address`, and
`coordinates` (`%Kagi.MapsResult.Coordinates{latitude:, longitude:}`). These fields are optional: `phone`, `url`,
`source`, `id`, `rating`, `review_count`, `price`, `distance`, `hours_now`, `types`, `links`, and `images`.

A failure returns `{:error, %Kagi.Error{reason: reason, message: message}}`.

## Development

`task check` runs the local checks, with no network access to Kagi.

`task test:live` sends real requests to Kagi and needs a session token:

```bash
export KAGI_SESSION_TOKEN="..."
task test:live
```
