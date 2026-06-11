defmodule Kagi.Query do
  @moduledoc false

  alias Kagi.Error

  @doc """
  Normalizes a search or maps query to one trimmed string.

  Accepts a binary or a list of binaries; anything else returns an
  `:invalid_option` error.
  """
  @spec normalize(term()) :: {:ok, String.t()} | {:error, Error.t()}
  def normalize(query) when is_binary(query), do: {:ok, String.trim(query)}

  def normalize(query) when is_list(query) do
    if string_list?(query) do
      {:ok, query |> Enum.join(" ") |> String.trim()}
    else
      {:error, invalid_query_error(query)}
    end
  end

  def normalize(query), do: {:error, invalid_query_error(query)}

  # Enum.all?/2 raises on improper lists; this stays an error tuple.
  @spec string_list?(term()) :: boolean()
  defp string_list?([]), do: true
  defp string_list?([head | tail]) when is_binary(head), do: string_list?(tail)
  defp string_list?(_other), do: false

  @spec invalid_query_error(term()) :: Error.t()
  defp invalid_query_error(query) do
    Error.new(
      :invalid_option,
      "query must be a string or a list of strings, got: #{inspect(query)}"
    )
  end
end
