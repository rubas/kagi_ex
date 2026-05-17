defmodule Kagi.SessionToken do
  @moduledoc false

  alias Kagi.Error

  @spec resolve(keyword()) :: {:ok, String.t()} | {:error, Error.t()}
  def resolve(options) when is_list(options) do
    if Keyword.has_key?(options, :session_token) do
      case normalize_token(Keyword.get(options, :session_token)) do
        nil ->
          {:error,
           Error.new(
             :missing_session_token,
             "invalid :session_token; expected a non-empty string"
           )}

        token ->
          {:ok, token}
      end
    else
      case normalize_token(Application.get_env(:kagi_ex, :session_token)) do
        nil ->
          {:error,
           Error.new(
             :missing_session_token,
             "missing session token; pass :session_token or configure :kagi_ex, :session_token"
           )}

        token ->
          {:ok, token}
      end
    end
  end

  @spec normalize_token(term()) :: String.t() | nil
  defp normalize_token(token) when is_binary(token) do
    token = String.trim(token)
    if token == "", do: nil, else: token
  end

  defp normalize_token(_token), do: nil
end
