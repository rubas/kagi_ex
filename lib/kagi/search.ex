defmodule Kagi.Search do
  @moduledoc """
  Search response returned by `Kagi.search/2` and `Kagi.search/3`.
  """

  alias Kagi.Client
  alias Kagi.Error
  alias Kagi.HTTP
  alias Kagi.SearchResult

  @type lens :: :default | :programming | :forums | :pdfs | :non_commercial | :world_news
  @type sort :: :recency | :website | :ad_trackers
  @type time_range :: :day | :week | :month | :year

  @type t :: %__MODULE__{results: [SearchResult.t()], related: [String.t()]}

  defstruct results: [], related: []

  @url "https://kagi.com/html/search"

  @doc false
  @spec request(Client.t(), String.t() | [String.t()], keyword()) ::
          {:ok, t()} | {:error, Error.t()}
  def request(%Client{} = client, query, options) when is_list(options) do
    with {:ok, params} <- query_params(query, options),
         {:ok, %{body: html}} <-
           HTTP.get(client, @url,
             params: params,
             headers: [{"cookie", "kagi_session=#{client.session_token}"}]
           ),
         {:ok, html} <- normalize_html(html) do
      parse(html, Keyword.get(options, :limit, 10))
    end
  end

  @doc false
  @spec parse(String.t(), non_neg_integer()) :: {:ok, t()} | {:error, Error.t()}
  def parse(html, limit) when is_binary(html) and is_integer(limit) and limit >= 0 do
    with {:ok, document} <- Floki.parse_document(html),
         :ok <- detect_challenge(document, html) do
      results =
        document
        |> parse_standard_results(limit)
        |> then(fn results ->
          results ++ parse_grouped_results(document, max(limit - length(results), 0))
        end)
        |> Enum.take(limit)

      {:ok, %__MODULE__{results: results, related: parse_related(document)}}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error, Error.new(:parse_error, "failed to parse search results: #{inspect(reason)}")}
    end
  end

  @spec normalize_html(term()) :: {:ok, String.t()} | {:error, Error.t()}
  defp normalize_html(html) when is_binary(html), do: {:ok, html}

  defp normalize_html(body) do
    {:error,
     Error.new(
       :parse_error,
       "expected search response body to be a string, got: #{inspect(body)}"
     )}
  end

  @spec query_params(String.t() | [String.t()], keyword()) ::
          {:ok, keyword()} | {:error, Error.t()}
  defp query_params(query, options) do
    with {:ok, query} <- build_query(query, options),
         {:ok, options} <- validate_options(options) do
      [
        {:plain, :r, options[:region]},
        {:mapped, :l, options[:lens], &lens_value/1},
        {:mapped, :order, options[:sort], &sort_value/1},
        {:mapped, :dr, options[:time], &time_value/1},
        {:plain, :from_date, options[:from]},
        {:plain, :to_date, options[:to]},
        {:plain, :verbatim, if(options[:verbatim], do: "1")}
      ]
      |> Enum.reduce_while({:ok, [q: query]}, &put_query_param/2)
    end
  end

  @spec validate_options(keyword()) :: {:ok, keyword()} | {:error, Error.t()}
  defp validate_options(options) do
    with :ok <- validate_time_range(options),
         :ok <- validate_limit(options[:limit]),
         :ok <- validate_date(:from, options[:from]),
         :ok <- validate_date(:to, options[:to]) do
      {:ok, options}
    end
  end

  @spec validate_time_range(keyword()) :: :ok | {:error, Error.t()}
  defp validate_time_range(options) do
    if options[:time] && (options[:from] || options[:to]) do
      {:error, Error.new(:invalid_option, ":time cannot be combined with :from or :to")}
    else
      :ok
    end
  end

  @spec validate_limit(term()) :: :ok | {:error, Error.t()}
  defp validate_limit(nil), do: :ok
  defp validate_limit(limit) when is_integer(limit) and limit >= 0, do: :ok

  defp validate_limit(_limit) do
    {:error, Error.new(:invalid_option, ":limit must be a non-negative integer")}
  end

  @spec validate_date(:from | :to, term()) :: :ok | {:error, Error.t()}
  defp validate_date(_key, nil), do: :ok

  defp validate_date(key, date) when is_binary(date) do
    if Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, date) do
      :ok
    else
      {:error, Error.new(:invalid_option, ":#{key} must use YYYY-MM-DD")}
    end
  end

  defp validate_date(key, _date) do
    {:error, Error.new(:invalid_option, ":#{key} must use YYYY-MM-DD")}
  end

  @spec build_query(String.t() | [String.t()], keyword()) ::
          {:ok, String.t()} | {:error, Error.t()}
  defp build_query(query, options) do
    query =
      query
      |> List.wrap()
      |> Enum.map_join(" ", &to_string/1)
      |> String.trim()

    if query == "" do
      {:error, Error.new(:invalid_option, "query must not be empty")}
    else
      query
      |> append_filter("site", options[:site])
      |> append_filter("filetype", options[:filetype])
      |> then(&{:ok, &1})
    end
  end

  @spec append_filter(String.t(), String.t(), String.t() | nil) :: String.t()
  defp append_filter(query, _name, nil), do: query
  defp append_filter(query, name, value), do: query <> " #{name}:#{value}"

  @spec put_query_param(tuple(), {:ok, keyword()}) ::
          {:cont, {:ok, keyword()}} | {:halt, {:error, Error.t()}}
  defp put_query_param({:plain, _key, nil}, {:ok, params}), do: {:cont, {:ok, params}}

  defp put_query_param({:plain, key, value}, {:ok, params}),
    do: {:cont, {:ok, Keyword.put(params, key, value)}}

  defp put_query_param({:mapped, _key, nil, _mapper}, {:ok, params}), do: {:cont, {:ok, params}}

  defp put_query_param({:mapped, key, value, mapper}, {:ok, params}) do
    case mapper.(value) do
      {:ok, api_value} -> {:cont, {:ok, Keyword.put(params, key, api_value)}}
      {:error, %Error{} = error} -> {:halt, {:error, error}}
    end
  end

  @spec lens_value(term()) :: {:ok, String.t()} | {:error, Error.t()}
  defp lens_value(:default), do: {:ok, "0"}
  defp lens_value(:programming), do: {:ok, "1"}
  defp lens_value(:forums), do: {:ok, "2"}
  defp lens_value(:pdfs), do: {:ok, "3"}
  defp lens_value(:non_commercial), do: {:ok, "4"}
  defp lens_value(:world_news), do: {:ok, "5"}

  defp lens_value(value) do
    {:error, Error.new(:invalid_option, "invalid lens: #{inspect(value)}")}
  end

  @spec sort_value(term()) :: {:ok, String.t()} | {:error, Error.t()}
  defp sort_value(:recency), do: {:ok, "2"}
  defp sort_value(:website), do: {:ok, "3"}
  defp sort_value(:ad_trackers), do: {:ok, "4"}

  defp sort_value(value) do
    {:error, Error.new(:invalid_option, "invalid sort: #{inspect(value)}")}
  end

  @spec time_value(term()) :: {:ok, String.t()} | {:error, Error.t()}
  defp time_value(:day), do: {:ok, "1"}
  defp time_value(:week), do: {:ok, "2"}
  defp time_value(:month), do: {:ok, "3"}
  defp time_value(:year), do: {:ok, "4"}

  defp time_value(value) do
    {:error, Error.new(:invalid_option, "invalid time: #{inspect(value)}")}
  end

  @spec detect_challenge(Floki.html_tree(), String.t()) :: :ok | {:error, Error.t()}
  defp detect_challenge(document, html) do
    has_results? =
      Floki.find(document, "#search-app") != [] or Floki.find(document, ".search-result") != [] or
        Floki.find(document, ".sr-group .__srgi") != []

    challenge? =
      html
      |> String.downcase()
      |> then(fn lower ->
        String.contains?(lower, "cf-challenge") or String.contains?(lower, "captcha") or
          String.contains?(lower, "challenge-platform") or
          String.contains?(lower, "just a moment")
      end)

    cond do
      has_results? ->
        :ok

      challenge? ->
        {:error, Error.new(:blocked, "Blocked by CAPTCHA/challenge")}

      true ->
        {:error, Error.new(:parse_error, "search response had no recognizable results structure")}
    end
  end

  @spec parse_standard_results(Floki.html_tree(), non_neg_integer()) :: [SearchResult.t()]
  defp parse_standard_results(document, limit) do
    document
    |> Floki.find(".search-result")
    |> Enum.flat_map(fn element ->
      with [link | _] <- Floki.find(element, ".__sri_title_link"),
           [url | _] <- Floki.attribute(link, "href") do
        [
          %SearchResult{
            url: url,
            title: link |> Floki.text() |> String.trim(),
            snippet: element |> Floki.find(".__sri-desc") |> Floki.text() |> String.trim()
          }
        ]
      else
        _value -> []
      end
    end)
    |> Enum.take(limit)
  end

  @spec parse_grouped_results(Floki.html_tree(), non_neg_integer()) :: [SearchResult.t()]
  defp parse_grouped_results(_document, 0), do: []

  defp parse_grouped_results(document, limit) do
    document
    |> Floki.find(".sr-group .__srgi")
    |> Enum.flat_map(fn element ->
      with [link | _] <- Floki.find(element, ".__srgi-title a"),
           [url | _] <- Floki.attribute(link, "href") do
        [
          %SearchResult{
            url: url,
            title: link |> Floki.text() |> String.trim(),
            snippet: element |> Floki.find(".__sri-desc") |> Floki.text() |> String.trim()
          }
        ]
      else
        _value -> []
      end
    end)
    |> Enum.take(limit)
  end

  @spec parse_related(Floki.html_tree()) :: [String.t()]
  defp parse_related(document) do
    document
    |> Floki.find(".related-searches a span")
    |> Enum.map(fn element -> element |> Floki.text() |> String.trim() end)
    |> Enum.reject(&(&1 == ""))
  end
end
