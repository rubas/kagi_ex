defmodule Kagi do
  @moduledoc """
  Typed client for [Kagi](https://kagi.com) Search, Summarizer, and Maps.

  Configure `:session_token` before calling the one-off helpers, or build a
  reusable `Kagi.Client` with `new/0`. Requests are built with `Req` and sent
  through `CloakedReq`.

  ## Quick start

      config :kagi_ex, session_token: "..."
      client = Kagi.new!()
      {:ok, search} = Kagi.search(client, "elixir req", lens: :programming, limit: 5)
      {:ok, summary} = Kagi.summarize(client, "https://elixir-lang.org")
      {:ok, places} = Kagi.maps(client, "coffee zurich", ll: "47.3769,8.5417")

  Non-bang functions return `{:ok, struct}` or `{:error, %Kagi.Error{}}`.
  Bang functions return the struct or raise `Kagi.Error`.
  """

  alias Kagi.Client
  alias Kagi.Error
  alias Kagi.Maps
  alias Kagi.Search
  alias Kagi.Summary

  @typedoc """
  Query argument accepted by `search/1..3` and `maps/1..3`.

  Lists are joined with spaces before the request is made.
  """
  @type query :: String.t() | [String.t()]

  @doc """
  Builds a reusable `Kagi.Client`.

  Reads `:session_token` and `:req_options` from application config. If the
  session token is missing or invalid, returns
  `{:error, %Kagi.Error{reason: :missing_session_token}}`.

  ## Application config

    * `:session_token` - Kagi session token string.
    * `:req_options` - keyword list merged into every `Req` request.

  Returns `{:error, %Kagi.Error{reason: :invalid_option}}` when
  `:req_options` is not a keyword list.

  ## Examples

      config :kagi_ex, session_token: "abc"
      {:ok, client} = Kagi.new()
  """
  @spec new() :: {:ok, Client.t()} | {:error, Error.t()}
  defdelegate new, to: Client

  @doc """
  Builds a reusable `Kagi.Client` or raises `Kagi.Error`.
  """
  @spec new!() :: Client.t()
  defdelegate new!, to: Client

  @doc """
  Searches Kagi and returns typed results.

  Accepts a prebuilt `Kagi.Client`. Use `search/2` or `search/1` to build the
  client from application config.

  ## Search options

    * `:limit` - maximum result count (default `10`); applied client-side.
    * `:region` - region code such as `"ch"`, `"us"`, `"de"`, or `"no_region"`.
    * `:lens` - `:default`, `:programming`, `:forums`, `:pdfs`,
      `:non_commercial`, or `:world_news`.
    * `:sort` - `:recency`, `:website`, or `:ad_trackers`.
    * `:time` - `:day`, `:week`, `:month`, or `:year`.
    * `:from` - start date as `YYYY-MM-DD`; cannot be combined with `:time`.
    * `:to` - end date as `YYYY-MM-DD`; cannot be combined with `:time`.
    * `:site` - appends a `site:` filter to the query.
    * `:filetype` - appends a `filetype:` filter to the query.
    * `:verbatim` - disables query expansion when `true`.

  Returns `{:error, %Kagi.Error{}}` for invalid options, HTTP failures,
  CAPTCHA/challenge pages, and parse failures.

  ## Examples

      client = Kagi.new!()
      {:ok, %Kagi.Search{results: results}} =
        Kagi.search(client, "elixir req http client", lens: :programming, limit: 3)

      Kagi.search("elixir lang", limit: 5)
  """
  @spec search(Client.t(), query(), keyword()) :: {:ok, Search.t()} | {:error, Error.t()}
  def search(%Client{} = client, query, options) do
    Search.request(client, query, options)
  end

  @doc """
  Searches Kagi with either a prebuilt client or application config.

  `search(client, query)` uses default search options. `search(query, options)`
  builds a client from application config and applies the supplied search
  options.
  """
  @spec search(Client.t(), query()) :: {:ok, Search.t()} | {:error, Error.t()}
  @spec search(query(), keyword()) :: {:ok, Search.t()} | {:error, Error.t()}
  def search(%Client{} = client, query), do: search(client, query, [])

  def search(query, options) when is_list(options) do
    with {:ok, client} <- Client.new() do
      Search.request(client, query, options)
    end
  end

  @doc """
  Searches Kagi using application config and default search options.

  Requires `config :kagi_ex, :session_token, "..."` or returns `{:error,
  %Kagi.Error{reason: :missing_session_token}}`.
  """
  @spec search(query()) :: {:ok, Search.t()} | {:error, Error.t()}
  def search(query), do: search(query, [])

  @doc """
  Searches Kagi and raises `Kagi.Error` on failure.
  """
  @spec search!(Client.t(), query(), keyword()) :: Search.t()
  def search!(%Client{} = client, query, options) do
    unwrap!(search(client, query, options))
  end

  @doc """
  Searches Kagi and raises `Kagi.Error` on failure.
  """
  @spec search!(Client.t(), query()) :: Search.t()
  @spec search!(query(), keyword()) :: Search.t()
  def search!(%Client{} = client, query), do: search!(client, query, [])

  def search!(query, options) when is_list(options) do
    unwrap!(search(query, options))
  end

  @doc """
  Searches Kagi with application config and raises `Kagi.Error` on failure.
  """
  @spec search!(query()) :: Search.t()
  def search!(query), do: search!(query, [])

  @doc """
  Summarizes a single URL with Kagi Summarizer.

  Accepts a prebuilt `Kagi.Client`. Use `summarize/2` or `summarize/1` to
  build the client from application config.

  ## Summary options

    * `:type` - `:summary` (default) or `:takeaway`.
    * `:lang` - target language code, default `"EN"`.

  Returns `{:error, %Kagi.Error{}}` for invalid options, HTTP failures,
  and parse failures.

  ## Examples

      client = Kagi.new!()
      {:ok, %Kagi.Summary{summary: markdown}} =
        Kagi.summarize(client, "https://www.rust-lang.org/learn", type: :takeaway)
  """
  @spec summarize(Client.t(), String.t(), keyword()) :: {:ok, Summary.t()} | {:error, Error.t()}
  def summarize(%Client{} = client, url, options) do
    Summary.request(client, url, options)
  end

  @doc """
  Summarizes a URL with either a prebuilt client or application config.

  `summarize(client, url)` uses default summary options. `summarize(url,
  options)` builds a client from application config and applies the supplied
  summary options.
  """
  @spec summarize(Client.t(), String.t()) :: {:ok, Summary.t()} | {:error, Error.t()}
  @spec summarize(String.t(), keyword()) :: {:ok, Summary.t()} | {:error, Error.t()}
  def summarize(%Client{} = client, url), do: summarize(client, url, [])

  def summarize(url, options) when is_list(options) do
    with {:ok, client} <- Client.new() do
      Summary.request(client, url, options)
    end
  end

  @doc """
  Summarizes a URL using application config and default summary options.
  """
  @spec summarize(String.t()) :: {:ok, Summary.t()} | {:error, Error.t()}
  def summarize(url), do: summarize(url, [])

  @doc """
  Summarizes a URL and raises `Kagi.Error` on failure.
  """
  @spec summarize!(Client.t(), String.t(), keyword()) :: Summary.t()
  def summarize!(%Client{} = client, url, options) do
    unwrap!(summarize(client, url, options))
  end

  @doc """
  Summarizes a URL and raises `Kagi.Error` on failure.
  """
  @spec summarize!(Client.t(), String.t()) :: Summary.t()
  @spec summarize!(String.t(), keyword()) :: Summary.t()
  def summarize!(%Client{} = client, url), do: summarize!(client, url, [])

  def summarize!(url, options) when is_list(options) do
    unwrap!(summarize(url, options))
  end

  @doc """
  Summarizes a URL with application config and raises `Kagi.Error` on failure.
  """
  @spec summarize!(String.t()) :: Summary.t()
  def summarize!(url), do: summarize!(url, [])

  @doc """
  Searches Kagi Maps for places matching a query.

  Accepts a prebuilt `Kagi.Client`. Use `maps/2` or `maps/1` to build the
  client from application config.

  ## Maps options

    * `:limit` - maximum result count (default `10`); applied client-side
      after sorting.
    * `:ll` - center coordinate as `"LAT,LON"` (e.g. `"47.3769,8.5417"`).
    * `:bbox` - bounding box as `"WEST,SOUTH,EAST,NORTH"`.
    * `:zoom` - zoom level as a number.
    * `:sort` - `:relevance` (server order), `:rating`, `:distance`, or
      `:price`. Price sorts by `$`-string length.
    * `:order` - `:asc` or `:desc`. Defaults are `:desc` for `:rating`,
      `:asc` for `:distance` and `:price`. `nil` values always sort last.

  Sorting and the limit apply client-side, after the API response is parsed.

  ## Examples

      client = Kagi.new!()
      {:ok, %Kagi.Maps{results: results}} =
        Kagi.maps(client, "coffee zurich", ll: "47.3769,8.5417", sort: :rating)
  """
  @spec maps(Client.t(), query(), keyword()) :: {:ok, Maps.t()} | {:error, Error.t()}
  def maps(%Client{} = client, query, options) do
    Maps.request(client, query, options)
  end

  @doc """
  Searches Kagi Maps with either a prebuilt client or application config.

  `maps(client, query)` uses default Maps options. `maps(query, options)`
  builds a client from application config and applies the supplied Maps
  options.
  """
  @spec maps(Client.t(), query()) :: {:ok, Maps.t()} | {:error, Error.t()}
  @spec maps(query(), keyword()) :: {:ok, Maps.t()} | {:error, Error.t()}
  def maps(%Client{} = client, query), do: maps(client, query, [])

  def maps(query, options) when is_list(options) do
    with {:ok, client} <- Client.new() do
      Maps.request(client, query, options)
    end
  end

  @doc """
  Searches Kagi Maps using application config and default Maps options.
  """
  @spec maps(query()) :: {:ok, Maps.t()} | {:error, Error.t()}
  def maps(query), do: maps(query, [])

  @doc """
  Searches Kagi Maps and raises `Kagi.Error` on failure.
  """
  @spec maps!(Client.t(), query(), keyword()) :: Maps.t()
  def maps!(%Client{} = client, query, options) do
    unwrap!(maps(client, query, options))
  end

  @doc """
  Searches Kagi Maps and raises `Kagi.Error` on failure.
  """
  @spec maps!(Client.t(), query()) :: Maps.t()
  @spec maps!(query(), keyword()) :: Maps.t()
  def maps!(%Client{} = client, query), do: maps!(client, query, [])

  def maps!(query, options) when is_list(options) do
    unwrap!(maps(query, options))
  end

  @doc """
  Searches Kagi Maps with application config and raises `Kagi.Error` on failure.
  """
  @spec maps!(query()) :: Maps.t()
  def maps!(query), do: maps!(query, [])

  @spec unwrap!({:ok, value} | {:error, Error.t()}) :: value when value: var
  defp unwrap!({:ok, value}), do: value
  defp unwrap!({:error, %Error{} = error}), do: raise(error)
end
