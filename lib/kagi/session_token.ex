defmodule Kagi.SessionToken do
  @moduledoc false

  alias Kagi.Error

  @spec resolve() :: {:ok, String.t()} | {:error, Error.t()}
  def resolve do
    case normalize_token(Application.get_env(:kagi_ex, :session_token)) do
      nil ->
        {:error,
         Error.new(
           :missing_session_token,
           "missing session token; configure :kagi_ex, :session_token"
         )}

      token ->
        {:ok, token}
    end
  end

  @spec normalize_token(term()) :: String.t() | nil
  defp normalize_token(token) when is_binary(token) do
    token = String.trim(token)
    if token == "", do: nil, else: token
  end

  defp normalize_token(_token), do: nil
end
