defmodule Kagi do
  @moduledoc """
  Typed client for Kagi Search and Summarizer.

  `Kagi` uses `Req` by default. Pass `transport: :cloaked_req` to route requests
  through `CloakedReq` instead.
  """

  alias Kagi.Client
  alias Kagi.Error
  alias Kagi.Search
  alias Kagi.Summary

  @doc """
  Builds a reusable Kagi client.

  Each option falls back to `Application.get_env(:kagi_ex, key)`. Per-call
  options always override the application config. The session token must be
  supplied through one of the two sources or `Kagi.new/1` returns
  `{:error, %Kagi.Error{reason: :missing_session_token}}`.

  ## Options

  - `:session_token` - Kagi session token string.
  - `:transport` - `:req` (default) or `:cloaked_req`.
  - `:req_options` - options merged into every `Req` request.
  - `:cloaked_req_options` - options passed to `CloakedReq.attach/2`.

  Returns `{:error, %Kagi.Error{}}` when required configuration is invalid or
  missing.
  """
  @spec new(keyword()) :: {:ok, Client.t()} | {:error, Error.t()}
  defdelegate new(options \\ []), to: Client

  @doc """
  Builds a reusable Kagi client or raises `Kagi.Error`.
  """
  @spec new!(keyword()) :: Client.t()
  defdelegate new!(options \\ []), to: Client

  @doc """
  Searches Kagi and returns typed search results.

  The first argument can be a `%Kagi.Client{}` or a query. Passing a client avoids
  resolving the session token for every request.

  ## Search options

  - `:limit` - maximum result count.
  - `:region` - region code such as `"ch"`, `"us"`, `"de"`, or `"no_region"`.
  - `:lens` - `:default`, `:programming`, `:forums`, `:pdfs`,
    `:non_commercial`, or `:world_news`.
  - `:sort` - `:recency`, `:website`, or `:ad_trackers`.
  - `:time` - `:day`, `:week`, `:month`, or `:year`.
  - `:from` - start date as `YYYY-MM-DD`; cannot be combined with `:time`.
  - `:to` - end date as `YYYY-MM-DD`; cannot be combined with `:time`.
  - `:site` - appends a `site:` filter.
  - `:filetype` - appends a `filetype:` filter.
  - `:verbatim` - disables query expansion when true.

  Returns `{:error, %Kagi.Error{}}` for missing tokens, invalid options, HTTP
  failures, CAPTCHA/challenge pages, and parse failures.
  """
  @spec search(Client.t(), String.t() | [String.t()], keyword()) ::
          {:ok, Search.t()} | {:error, Error.t()}
  def search(%Client{} = client, query, options) do
    Search.request(client, query, options)
  end

  @spec search(Client.t(), String.t() | [String.t()]) :: {:ok, Search.t()} | {:error, Error.t()}
  def search(%Client{} = client, query), do: search(client, query, [])

  @spec search(String.t() | [String.t()], keyword()) :: {:ok, Search.t()} | {:error, Error.t()}
  def search(query, options) do
    with {:ok, client} <- Client.new(options) do
      Search.request(client, query, options)
    end
  end

  @spec search(String.t() | [String.t()]) :: {:ok, Search.t()} | {:error, Error.t()}
  def search(query), do: search(query, [])

  @doc """
  Searches Kagi or raises `Kagi.Error`.
  """
  @spec search!(Client.t(), String.t() | [String.t()], keyword()) :: Search.t()
  def search!(%Client{} = client, query, options) do
    unwrap!(search(client, query, options))
  end

  @spec search!(Client.t(), String.t() | [String.t()]) :: Search.t()
  def search!(%Client{} = client, query), do: search!(client, query, [])

  @spec search!(String.t() | [String.t()], keyword()) :: Search.t()
  def search!(query, options) do
    unwrap!(search(query, options))
  end

  @spec search!(String.t() | [String.t()]) :: Search.t()
  def search!(query), do: search!(query, [])

  @doc """
  Summarizes one URL with Kagi Summarizer.

  ## Summary options

  - `:type` - `:summary` or `:takeaway`.
  - `:lang` - target language code, default `"EN"`.

  Returns `{:error, %Kagi.Error{}}` for missing tokens, invalid options, HTTP
  failures, and parse failures.
  """
  @spec summarize(Client.t(), String.t(), keyword()) :: {:ok, Summary.t()} | {:error, Error.t()}
  def summarize(%Client{} = client, url, options) do
    Summary.request(client, url, options)
  end

  @spec summarize(Client.t(), String.t()) :: {:ok, Summary.t()} | {:error, Error.t()}
  def summarize(%Client{} = client, url), do: summarize(client, url, [])

  @spec summarize(String.t(), keyword()) :: {:ok, Summary.t()} | {:error, Error.t()}
  def summarize(url, options) do
    with {:ok, client} <- Client.new(options) do
      Summary.request(client, url, options)
    end
  end

  @spec summarize(String.t()) :: {:ok, Summary.t()} | {:error, Error.t()}
  def summarize(url), do: summarize(url, [])

  @doc """
  Summarizes one URL or raises `Kagi.Error`.
  """
  @spec summarize!(Client.t(), String.t(), keyword()) :: Summary.t()
  def summarize!(%Client{} = client, url, options) do
    unwrap!(summarize(client, url, options))
  end

  @spec summarize!(Client.t(), String.t()) :: Summary.t()
  def summarize!(%Client{} = client, url), do: summarize!(client, url, [])

  @spec summarize!(String.t(), keyword()) :: Summary.t()
  def summarize!(url, options) do
    unwrap!(summarize(url, options))
  end

  @spec summarize!(String.t()) :: Summary.t()
  def summarize!(url), do: summarize!(url, [])

  @spec unwrap!({:ok, value} | {:error, Error.t()}) :: value when value: var
  defp unwrap!({:ok, value}), do: value
  defp unwrap!({:error, %Error{} = error}), do: raise(error)
end
