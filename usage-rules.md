# Using kagi_ex

`kagi_ex` is a typed client for Kagi Search, Summarizer, and Maps. Use it when Elixir code needs Kagi results without shelling out to the Rust CLI.

## Canonical Usage

Build a reusable client when making more than one request:

```elixir
client = Kagi.new!(session_token: my_session_token())

{:ok, search} = Kagi.search(client, "elixir req", lens: :programming, limit: 5)
{:ok, summary} = Kagi.summarize(client, "https://elixir-lang.org")
{:ok, maps} = Kagi.maps(client, "coffee zurich", sort: :rating)
```

For one-off calls, pass the same options directly:

```elixir
{:ok, search} = Kagi.search("elixir req", session_token: "...")
```

## Authentication

Resolve the Kagi session token with one of:

- `:session_token` option
- `config :kagi_ex, :session_token, "..."`

Missing tokens return `{:error, %Kagi.Error{reason: :missing_session_token}}`.

## Transport

Default transport is normal `Req`. `:transport`, `:req_options`, and `:cloaked_req_options` are configured via application config only - they are not accepted per call.

```elixir
config :kagi_ex,
  session_token: System.fetch_env!("KAGI_SESSION_TOKEN"),
  transport: :cloaked_req,
  cloaked_req_options: [impersonate: :chrome_136]
```

`cloaked_req` is an optional dependency. Add `{:cloaked_req, "~> 0.3"}` to your deps when selecting the `:cloaked_req` transport.

## Returned Types

- Search: `%Kagi.Search{results: [%Kagi.SearchResult{}], related: [String.t()]}`
- Summarizer: `%Kagi.Summary{summary: String.t()}`
- Maps: `%Kagi.Maps{results: [%Kagi.MapsResult{}]}` where each result carries `coordinates: %Kagi.MapsResult.Coordinates{}` and optional fields like `rating`, `distance`, `price`
- Failure: `%Kagi.Error{reason: atom(), message: String.t()}`
