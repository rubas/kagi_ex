defmodule Kagi.Maps do
  @moduledoc """
  Maps response returned by `Kagi.maps/1..3`.

  Hits `https://kagi.com/maps/api/v1/search`, parses the JSON `pois` array
  into `Kagi.MapsResult` rows, then applies the optional `:sort`, `:order`,
  and `:limit` options client-side.

  ## Fields

    * `:results` - list of `Kagi.MapsResult` rows in the order they should be
      presented after client-side sorting and truncation.
  """

  alias Kagi.Client
  alias Kagi.Error
  alias Kagi.HTTP
  alias Kagi.MapsResult
  alias Kagi.MapsResult.Coordinates

  @typedoc "Maps sort mode passed via the `:sort` option."
  @type sort :: :relevance | :rating | :distance | :price

  @typedoc "Sort direction passed via the `:order` option."
  @type order :: :asc | :desc

  @typedoc "A parsed Kagi Maps response."
  @type t :: %__MODULE__{results: [MapsResult.t()]}

  defstruct results: []

  @url "https://kagi.com/maps/api/v1/search"

  @doc false
  @spec request(Client.t(), String.t() | [String.t()], keyword()) ::
          {:ok, t()} | {:error, Error.t()}
  def request(%Client{} = client, query, options) when is_list(options) do
    with {:ok, query} <- build_query(query),
         {:ok, params} <- query_params(query, options),
         {:ok, %{body: body}} <-
           HTTP.get(client, @url,
             params: params,
             headers: [
               {"cookie", "kagi_session=#{client.session_token}"},
               {"referer", "https://kagi.com/maps"}
             ]
           ),
         {:ok, json} <- normalize_body(body),
         {:ok, pois} <- extract_pois(json),
         {:ok, limit} <- limit(options) do
      results =
        pois
        |> Enum.map(&parse_poi/1)
        |> sort_results(options[:sort], options[:order])
        |> Enum.take(limit)

      {:ok, %__MODULE__{results: results}}
    end
  end

  @doc false
  @spec parse(map(), non_neg_integer()) :: {:ok, t()} | {:error, Error.t()}
  def parse(json, limit) when is_map(json) and is_integer(limit) and limit >= 0 do
    with {:ok, pois} <- extract_pois(json) do
      results = pois |> Enum.map(&parse_poi/1) |> Enum.take(limit)
      {:ok, %__MODULE__{results: results}}
    end
  end

  @spec build_query(String.t() | [String.t()]) :: {:ok, String.t()} | {:error, Error.t()}
  defp build_query(query) do
    query =
      query
      |> List.wrap()
      |> Enum.map_join(" ", &to_string/1)
      |> String.trim()

    if query == "" do
      {:error, Error.new(:invalid_option, "query must not be empty")}
    else
      {:ok, query}
    end
  end

  @spec query_params(String.t(), keyword()) :: {:ok, keyword()} | {:error, Error.t()}
  defp query_params(query, options) do
    with :ok <- validate_sort(options[:sort]),
         :ok <- validate_order(options[:order]),
         {:ok, ll} <- coerce_coordinate(options[:ll]),
         {:ok, bbox} <- coerce_bbox(options[:bbox]),
         {:ok, zoom} <- coerce_zoom(options[:zoom]) do
      params =
        [q: query]
        |> put_param(:ll, ll)
        |> put_param(:bbox, bbox)
        |> put_param(:z, zoom)

      {:ok, params}
    end
  end

  @spec put_param(keyword(), atom(), term() | nil) :: keyword()
  defp put_param(params, _key, nil), do: params
  defp put_param(params, key, value), do: Keyword.put(params, key, value)

  @spec validate_sort(term()) :: :ok | {:error, Error.t()}
  defp validate_sort(nil), do: :ok
  defp validate_sort(sort) when sort in [:relevance, :rating, :distance, :price], do: :ok

  defp validate_sort(value) do
    {:error, Error.new(:invalid_option, "invalid maps sort: #{inspect(value)}")}
  end

  @spec validate_order(term()) :: :ok | {:error, Error.t()}
  defp validate_order(nil), do: :ok
  defp validate_order(order) when order in [:asc, :desc], do: :ok

  defp validate_order(value) do
    {:error, Error.new(:invalid_option, "invalid maps order: #{inspect(value)}")}
  end

  @spec coerce_coordinate(term()) :: {:ok, String.t() | nil} | {:error, Error.t()}
  defp coerce_coordinate(nil), do: {:ok, nil}

  defp coerce_coordinate(value) when is_binary(value) do
    with {:ok, [lat, lon]} <- parse_numbers(value, 2, "LAT,LON"),
         :ok <- ensure_range(lat, -90.0, 90.0, "latitude"),
         :ok <- ensure_range(lon, -180.0, 180.0, "longitude") do
      {:ok, value}
    end
  end

  defp coerce_coordinate(value) do
    {:error,
     Error.new(
       :invalid_option,
       ":ll must be a string of the form LAT,LON, got: #{inspect(value)}"
     )}
  end

  @spec coerce_bbox(term()) :: {:ok, String.t() | nil} | {:error, Error.t()}
  defp coerce_bbox(nil), do: {:ok, nil}

  defp coerce_bbox(value) when is_binary(value) do
    with {:ok, [west, south, east, north]} <-
           parse_numbers(value, 4, "WEST,SOUTH,EAST,NORTH"),
         :ok <- ensure_range(west, -180.0, 180.0, "longitude"),
         :ok <- ensure_range(east, -180.0, 180.0, "longitude"),
         :ok <- ensure_range(south, -90.0, 90.0, "latitude"),
         :ok <- ensure_range(north, -90.0, 90.0, "latitude"),
         :ok <- ensure_distinct(west, east),
         :ok <- ensure_ordered(south, north) do
      {:ok, value}
    end
  end

  defp coerce_bbox(value) do
    {:error,
     Error.new(
       :invalid_option,
       ":bbox must be a string of the form WEST,SOUTH,EAST,NORTH, got: #{inspect(value)}"
     )}
  end

  @spec coerce_zoom(term()) :: {:ok, String.t() | nil} | {:error, Error.t()}
  defp coerce_zoom(nil), do: {:ok, nil}

  defp coerce_zoom(value) when is_integer(value) or is_float(value) do
    {:ok, to_string(value)}
  end

  defp coerce_zoom(value) do
    {:error, Error.new(:invalid_option, ":zoom must be a number, got: #{inspect(value)}")}
  end

  @spec parse_numbers(String.t(), pos_integer(), String.t()) ::
          {:ok, [float()]} | {:error, Error.t()}
  defp parse_numbers(value, expected, format) do
    parts = value |> String.split(",") |> Enum.map(&String.trim/1)

    if length(parts) == expected do
      parts
      |> Enum.reduce_while([], &parse_number_part/2)
      |> case do
        {:error, :invalid} -> {:error, invalid_numbers_error(value, format)}
        numbers -> {:ok, Enum.reverse(numbers)}
      end
    else
      {:error, invalid_numbers_error(value, format)}
    end
  end

  @spec parse_number_part(String.t(), [float()]) ::
          {:cont, [float()]} | {:halt, {:error, :invalid}}
  defp parse_number_part(part, acc) do
    case Float.parse(part) do
      {number, ""} -> {:cont, [number | acc]}
      _other -> {:halt, {:error, :invalid}}
    end
  end

  @spec invalid_numbers_error(String.t(), String.t()) :: Error.t()
  defp invalid_numbers_error(value, format) do
    Error.new(:invalid_option, "invalid value #{inspect(value)}, expected #{format}")
  end

  @spec ensure_range(float(), float(), float(), String.t()) :: :ok | {:error, Error.t()}
  defp ensure_range(value, min, max, label) do
    if value >= min and value <= max do
      :ok
    else
      {:error,
       Error.new(:invalid_option, "#{label} #{value} is outside the range #{min}..#{max}")}
    end
  end

  @spec ensure_distinct(float(), float()) :: :ok | {:error, Error.t()}
  defp ensure_distinct(west, east) do
    if west == east do
      {:error, Error.new(:invalid_option, "bbox WEST and EAST must differ")}
    else
      :ok
    end
  end

  @spec ensure_ordered(float(), float()) :: :ok | {:error, Error.t()}
  defp ensure_ordered(south, north) do
    if south < north do
      :ok
    else
      {:error, Error.new(:invalid_option, "bbox SOUTH must be less than NORTH")}
    end
  end

  @spec limit(keyword()) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  defp limit(options) do
    case Keyword.get(options, :limit, 10) do
      value when is_integer(value) and value >= 0 ->
        {:ok, value}

      value ->
        {:error,
         Error.new(
           :invalid_option,
           ":limit must be a non-negative integer, got: #{inspect(value)}"
         )}
    end
  end

  @spec normalize_body(term()) :: {:ok, map()} | {:error, Error.t()}
  defp normalize_body(body) when is_map(body), do: {:ok, body}

  defp normalize_body(body) when is_binary(body) do
    case JSON.decode(body) do
      {:ok, value} when is_map(value) ->
        {:ok, value}

      {:ok, value} ->
        {:error,
         Error.new(:parse_error, "maps response must be a JSON object, got: #{inspect(value)}")}

      {:error, reason} ->
        {:error, Error.new(:parse_error, "failed to decode maps JSON: #{inspect(reason)}")}
    end
  end

  defp normalize_body(body) do
    {:error,
     Error.new(:parse_error, "expected maps response body to be JSON, got: #{inspect(body)}")}
  end

  @spec extract_pois(map()) :: {:ok, [map()]} | {:error, Error.t()}
  defp extract_pois(%{"pois" => pois}) when is_list(pois), do: {:ok, pois}

  defp extract_pois(json) do
    {:error, Error.new(:parse_error, "maps response missing 'pois' array: #{inspect(json)}")}
  end

  @spec parse_poi(map()) :: MapsResult.t()
  defp parse_poi(poi) when is_map(poi) do
    %MapsResult{
      name: Map.get(poi, "name"),
      address: Map.get(poi, "address"),
      coordinates: parse_coordinates(Map.get(poi, "coordinates")),
      phone: Map.get(poi, "phone"),
      url: Map.get(poi, "url"),
      source: Map.get(poi, "source"),
      id: Map.get(poi, "id_k") || Map.get(poi, "id"),
      rating: Map.get(poi, "rating"),
      review_count: Map.get(poi, "reviewCount"),
      price: Map.get(poi, "price"),
      distance: Map.get(poi, "distance"),
      hours_now: Map.get(poi, "hours_now"),
      types: Map.get(poi, "types"),
      links: Map.get(poi, "links"),
      images: Map.get(poi, "images")
    }
  end

  @spec parse_coordinates(term()) :: Coordinates.t() | nil
  defp parse_coordinates(%{"latitude" => lat, "longitude" => lon}) do
    %Coordinates{latitude: lat, longitude: lon}
  end

  defp parse_coordinates(_other), do: nil

  @doc false
  @spec sort_results([MapsResult.t()], sort() | nil, order() | nil) :: [MapsResult.t()]
  def sort_results(results, nil, _order), do: results
  def sort_results(results, :relevance, _order), do: results

  def sort_results(results, sort, order) do
    direction = direction(order || default_order(sort))
    key_fun = key_fun(sort)
    Enum.sort_by(results, key_fun, sort_compare(direction))
  end

  @spec key_fun(sort()) :: (MapsResult.t() -> term())
  defp key_fun(:rating), do: & &1.rating
  defp key_fun(:distance), do: & &1.distance
  defp key_fun(:price), do: fn result -> result.price && String.length(result.price) end

  @spec default_order(sort()) :: order()
  defp default_order(:rating), do: :desc
  defp default_order(:distance), do: :asc
  defp default_order(:price), do: :asc

  @spec direction(order()) :: :asc | :desc
  defp direction(:asc), do: :asc
  defp direction(:desc), do: :desc

  @spec sort_compare(:asc | :desc) :: (term(), term() -> boolean())
  defp sort_compare(:asc) do
    fn left, right ->
      case {left, right} do
        {nil, nil} -> true
        {nil, _right} -> false
        {_left, nil} -> true
        {left, right} -> left <= right
      end
    end
  end

  defp sort_compare(:desc) do
    fn left, right ->
      case {left, right} do
        {nil, nil} -> true
        {nil, _right} -> false
        {_left, nil} -> true
        {left, right} -> left >= right
      end
    end
  end
end
