defmodule Kagi.SessionToken do
  @moduledoc false

  alias Kagi.Error

  # RFC 6265 cookie-octets: printable US-ASCII except whitespace, double
  # quotes, commas, semicolons, and backslashes. \A and \z keep a trailing
  # newline from slipping past the $ anchor.
  @cookie_octets ~r/\A[\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]+\z/

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
        validate_token(token)
    end
  end

  @spec normalize_token(term()) :: String.t() | nil
  defp normalize_token(token) when is_binary(token) do
    token = String.trim(token)
    if token == "", do: nil, else: token
  end

  defp normalize_token(_token), do: nil

  @spec validate_token(String.t()) :: {:ok, String.t()} | {:error, Error.t()}
  defp validate_token(token) do
    if Regex.match?(@cookie_octets, token) do
      {:ok, token}
    else
      {:error,
       Error.new(
         :invalid_session_token,
         "session token contains characters not allowed in a cookie value; " <>
           "configure only the kagi_session value, not a full Cookie header"
       )}
    end
  end
end
