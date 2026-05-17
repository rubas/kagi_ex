defmodule Kagi do
  @moduledoc """
  Typed client for [Kagi](https://kagi.com) Search, Summarizer, and Maps.

  `Kagi` builds `Req` requests and sends them through `CloakedReq`. See
  `Kagi.Client` for the full list of fields.

  ## Quick start

      config :kagi_ex, session_token: "..."
      client = Kagi.new!()
      {:ok, search} = Kagi.search(client, "elixir req", lens: :programming, limit: 5)
      {:ok, summary} = Kagi.summarize(client, "https://elixir-lang.org")
      {:ok, places} = Kagi.maps(client, "coffee zurich", ll: "47.3769,8.5417")

  Every public function in this module returns either `{:ok, struct}` or
  `{:error, %Kagi.Error{}}`. The `!`-suffixed variants raise on error.
  """

  alias Kagi.Client
  alias Kagi.Error
  alias Kagi.Maps
  alias Kagi.Search
  alias Kagi.Summary

  @typedoc """
  Query argument accepted by `search/1..3` and `maps/1..3`.

  A list is joined with spaces before being sent.
  """
  @type query :: String.t() | [String.t()]

  @doc """
  Builds a reusable `Kagi.Client`.

  The session token is read from `Application.get_env(:kagi_ex,
  :session_token)`. `:req_options` is also read from application config. If
  no session token is configured, `new/0` returns
  `{:error, %Kagi.Error{reason: :missing_session_token}}`.

  ## Application config

    * `:session_token` - Kagi session token string.
    * `:req_options` - keyword list merged into every `Req` request.

  Returns `{:error, %Kagi.Error{}}` when required configuration is invalid
  or missing.

  ## Examples

      config :kagi_ex, session_token: "abc"
      {:ok, client} = Kagi.new()
  """
  @spec new() :: {:ok, Client.t()} | {:error, Error.t()}
  defdelegate new, to: Client

  @doc """
  Same as `new/0` but raises `Kagi.Error` on failure.
  """
  @spec new!() :: Client.t()
  defdelegate new!, to: Client

  @doc """
  Searches Kagi and returns typed results.

  Accepts either a prebuilt `Kagi.Client` or search options for a one-off
  request. One-off calls build a client from application config.

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
  Same as `search/3` but with default options, or same as `search/2` (without
  client) when called as `search(query, options)`.
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
  Searches Kagi using only an application-configured session token.

  Equivalent to `search(query, [])`. Requires `config :kagi_ex,
  :session_token, "..."` or it returns `{:error,
  %Kagi.Error{reason: :missing_session_token}}`.
  """
  @spec search(query()) :: {:ok, Search.t()} | {:error, Error.t()}
  def search(query), do: search(query, [])

  @doc """
  Same as `search/3` but raises `Kagi.Error` on failure.
  """
  @spec search!(Client.t(), query(), keyword()) :: Search.t()
  def search!(%Client{} = client, query, options) do
    unwrap!(search(client, query, options))
  end

  @doc """
  Same as `search/2` but raises `Kagi.Error` on failure.
  """
  @spec search!(Client.t(), query()) :: Search.t()
  @spec search!(query(), keyword()) :: Search.t()
  def search!(%Client{} = client, query), do: search!(client, query, [])

  def search!(query, options) when is_list(options) do
    unwrap!(search(query, options))
  end

  @doc """
  Same as `search/1` but raises `Kagi.Error` on failure.
  """
  @spec search!(query()) :: Search.t()
  def search!(query), do: search!(query, [])

  @doc """
  Summarizes a single URL with Kagi Summarizer.

  Accepts either a prebuilt `Kagi.Client` or raw `options` for a one-off
  request, mirroring `search/3`.

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
  Same as `summarize/3` with default options, or same as `summarize/2` (without
  client) when called as `summarize(url, options)`.
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
  Summarizes a URL using only an application-configured session token.

  Equivalent to `summarize(url, [])`.
  """
  @spec summarize(String.t()) :: {:ok, Summary.t()} | {:error, Error.t()}
  def summarize(url), do: summarize(url, [])

  @doc """
  Same as `summarize/3` but raises `Kagi.Error` on failure.
  """
  @spec summarize!(Client.t(), String.t(), keyword()) :: Summary.t()
  def summarize!(%Client{} = client, url, options) do
    unwrap!(summarize(client, url, options))
  end

  @doc """
  Same as `summarize/2` but raises `Kagi.Error` on failure.
  """
  @spec summarize!(Client.t(), String.t()) :: Summary.t()
  @spec summarize!(String.t(), keyword()) :: Summary.t()
  def summarize!(%Client{} = client, url), do: summarize!(client, url, [])

  def summarize!(url, options) when is_list(options) do
    unwrap!(summarize(url, options))
  end

  @doc """
  Same as `summarize/1` but raises `Kagi.Error` on failure.
  """
  @spec summarize!(String.t()) :: Summary.t()
  def summarize!(url), do: summarize!(url, [])

  @doc """
  Searches Kagi Maps for places matching a query.

  Accepts either a prebuilt `Kagi.Client` or raw `options` for a one-off
  request, mirroring `search/3`.

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
  Same as `maps/3` with default options, or same as `maps/2` (without client)
  when called as `maps(query, options)`.
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
  Searches Kagi Maps using only an application-configured session token.

  Equivalent to `maps(query, [])`.
  """
  @spec maps(query()) :: {:ok, Maps.t()} | {:error, Error.t()}
  def maps(query), do: maps(query, [])

  @doc """
  Same as `maps/3` but raises `Kagi.Error` on failure.
  """
  @spec maps!(Client.t(), query(), keyword()) :: Maps.t()
  def maps!(%Client{} = client, query, options) do
    unwrap!(maps(client, query, options))
  end

  @doc """
  Same as `maps/2` but raises `Kagi.Error` on failure.
  """
  @spec maps!(Client.t(), query()) :: Maps.t()
  @spec maps!(query(), keyword()) :: Maps.t()
  def maps!(%Client{} = client, query), do: maps!(client, query, [])

  def maps!(query, options) when is_list(options) do
    unwrap!(maps(query, options))
  end

  @doc """
  Same as `maps/1` but raises `Kagi.Error` on failure.
  """
  @spec maps!(query()) :: Maps.t()
  def maps!(query), do: maps!(query, [])

  @spec unwrap!({:ok, value} | {:error, Error.t()}) :: value when value: var
  defp unwrap!({:ok, value}), do: value
  defp unwrap!({:error, %Error{} = error}), do: raise(error)
end
