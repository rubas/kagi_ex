defmodule Kagi.Summary do
  @moduledoc """
  Summary response returned by `Kagi.summarize/1..3`.

  Contains the Markdown returned by Kagi Summarizer.

  ## Fields

    * `:summary` - Markdown summary text.
  """

  alias Kagi.Client
  alias Kagi.Error
  alias Kagi.HTTP

  @typedoc "Summary style requested via the `:type` option."
  @type summary_type :: :summary | :takeaway

  @typedoc "A parsed Kagi summarizer response."
  @type t :: %__MODULE__{summary: String.t()}

  defstruct [:summary]

  @url "https://kagi.com/mother/summary_labs"

  @doc false
  @spec request(Client.t(), String.t(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def request(%Client{} = client, url, options) when is_binary(url) and is_list(options) do
    with {:ok, params} <- query_params(url, options),
         {:ok, %{body: body}} <-
           HTTP.get(client, @url,
             params: params,
             headers: [
               {"accept", "application/vnd.kagi.stream"},
               {"cookie", "kagi_session=#{client.session_token}"},
               {"referer", "https://kagi.com/summarizer"}
             ]
           ),
         {:ok, body} <- normalize_body(body) do
      parse_stream(body)
    end
  end

  @doc false
  @spec parse_stream(binary()) :: {:ok, t()} | {:error, Error.t()}
  def parse_stream(<<>>) do
    {:error, Error.new(:parse_error, "Empty response from summarizer")}
  end

  def parse_stream(body) when is_binary(body) do
    with {:ok, chunk} <- last_data_chunk(body),
         {:ok, json} <- decode_chunk(chunk),
         :ok <- detect_summary_error(json),
         {:ok, markdown} <- extract_markdown(json) do
      {:ok, %__MODULE__{summary: markdown}}
    end
  end

  @spec normalize_body(term()) :: {:ok, binary()} | {:error, Error.t()}
  defp normalize_body(body) when is_binary(body), do: {:ok, body}

  defp normalize_body(body) do
    {:error,
     Error.new(:parse_error, "expected summary response body to be binary, got: #{inspect(body)}")}
  end

  @spec query_params(String.t(), keyword()) :: {:ok, keyword()} | {:error, Error.t()}
  defp query_params(url, options) do
    with {:ok, summary_type} <- summary_type(Keyword.get(options, :type, :summary)) do
      {:ok,
       [
         url: url,
         stream: "1",
         target_language: Keyword.get(options, :lang, "EN"),
         summary_type: summary_type
       ]}
    end
  end

  @spec summary_type(term()) :: {:ok, String.t()} | {:error, Error.t()}
  defp summary_type(:summary), do: {:ok, "summary"}
  defp summary_type(:takeaway), do: {:ok, "takeaway"}

  defp summary_type(value) do
    {:error, Error.new(:invalid_option, "invalid summary type: #{inspect(value)}")}
  end

  @spec last_data_chunk(binary()) :: {:ok, String.t()} | {:error, Error.t()}
  defp last_data_chunk(body) do
    body
    |> :binary.split(<<0>>, [:global])
    |> Enum.reverse()
    |> Enum.find(fn chunk -> chunk |> String.trim() |> Kernel.!==("") end)
    |> case do
      nil -> {:error, Error.new(:parse_error, "No data chunks in response")}
      chunk -> {:ok, String.trim(chunk)}
    end
  end

  @spec decode_chunk(String.t()) :: {:ok, map()} | {:error, Error.t()}
  defp decode_chunk(chunk) do
    json =
      cond do
        String.starts_with?(chunk, "final:") ->
          chunk |> String.replace_prefix("final:", "") |> String.trim()

        String.starts_with?(chunk, "new_message.json:") ->
          chunk |> String.replace_prefix("new_message.json:", "") |> String.trim()

        true ->
          chunk
      end

    case JSON.decode(json) do
      {:ok, value} when is_map(value) ->
        {:ok, value}

      {:ok, value} ->
        {:error,
         Error.new(:parse_error, "summary JSON must be an object, got: #{inspect(value)}")}

      {:error, reason} ->
        {:error, Error.new(:parse_error, "Failed to parse summary JSON: #{inspect(reason)}")}
    end
  end

  @spec detect_summary_error(map()) :: :ok | {:error, Error.t()}
  defp detect_summary_error(%{"state" => "error"} = json) do
    {:error,
     Error.new(:parse_error, "Summarizer error: #{Map.get(json, "reply", "Unknown error")}")}
  end

  defp detect_summary_error(_json), do: :ok

  @spec extract_markdown(map()) :: {:ok, String.t()} | {:error, Error.t()}
  defp extract_markdown(json) do
    markdown = json["md"] || get_in(json, ["output_data", "markdown"])

    cond do
      not is_binary(markdown) ->
        {:error, Error.new(:parse_error, "Missing markdown in response")}

      markdown == "" ->
        {:error, Error.new(:parse_error, "Empty summary returned")}

      true ->
        {:ok, markdown}
    end
  end
end
