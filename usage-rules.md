# Using kagi_ex

`kagi_ex` is a typed client for Kagi Search, Summarizer, and Maps. Use it when Elixir code needs Kagi results without shelling out to the Rust CLI.

## Canonical Usage

Build a reusable client when making more than one request:

```elixir
client = Kagi.new!()

{:ok, search} = Kagi.search(client, "elixir req", lens: :programming, limit: 5)
{:ok, summary} = Kagi.summarize(client, "https://elixir-lang.org")
{:ok, maps} = Kagi.maps(client, "coffee zurich", sort: :rating)
```

For one-off calls, use the application-configured client:

```elixir
{:ok, search} = Kagi.search("elixir req")
```

## Authentication

Configure the Kagi session token with `config :kagi_ex, :session_token, "..."`.

Missing tokens return `{:error, %Kagi.Error{reason: :missing_session_token}}`.

## Transport

Requests always use `CloakedReq`. Configure `:req_options` via application
config when you need to override the default `Req` request options.

```elixir
config :kagi_ex,
  session_token: System.fetch_env!("KAGI_SESSION_TOKEN"),
  req_options: [receive_timeout: 30_000]
```

## Returned Types

- Search: `%Kagi.Search{results: [%Kagi.SearchResult{}], related: [String.t()]}`
- Summarizer: `%Kagi.Summary{summary: String.t()}`
- Maps: `%Kagi.Maps{results: [%Kagi.MapsResult{}]}` where each result carries `coordinates: %Kagi.MapsResult.Coordinates{}` and optional fields like `rating`, `distance`, `price`
- Failure: `%Kagi.Error{reason: atom(), message: String.t()}`
