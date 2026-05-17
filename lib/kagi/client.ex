defmodule Kagi.Client do
  @moduledoc """
  Reusable configuration for Kagi requests.

  A client stores the configured session token and request options. Building a
  client performs no network I/O.

  ## Fields

    * `:session_token` - Kagi session token string.
    * `:req_options` - keyword list merged into each `Req` request.
  """

  alias Kagi.Error

  @typedoc "A configured Kagi client."
  @type t :: %__MODULE__{
          session_token: String.t(),
          req_options: keyword()
        }

  defstruct [:session_token, req_options: []]

  @doc """
  Builds a `%Kagi.Client{}` from application config.

  Reads `:session_token` and `:req_options` from `:kagi_ex` config. Returns
  `{:error, %Kagi.Error{}}` when the token is missing or `:req_options` is not
  a keyword list.

  ## Examples

      config :kagi_ex, session_token: "abc"
      {:ok, client} = Kagi.Client.new()
      {:error, %Kagi.Error{reason: :missing_session_token}} = Kagi.Client.new()
  """
  @spec new() :: {:ok, t()} | {:error, Error.t()}
  def new do
    with {:ok, session_token} <- Kagi.SessionToken.resolve(),
         {:ok, req_options} <- validate_keyword_option(:req_options) do
      {:ok, %__MODULE__{session_token: session_token, req_options: req_options}}
    end
  end

  @doc """
  Builds a `%Kagi.Client{}` or raises `Kagi.Error`.
  """
  @spec new!() :: t()
  def new! do
    case new() do
      {:ok, client} -> client
      {:error, %Error{} = error} -> raise error
    end
  end

  @spec configured(atom(), term()) :: term()
  defp configured(key, default) do
    Application.get_env(:kagi_ex, key, default)
  end

  @spec validate_keyword_option(atom()) :: {:ok, keyword()} | {:error, Error.t()}
  defp validate_keyword_option(key) do
    value = configured(key, [])

    if Keyword.keyword?(value) do
      {:ok, value}
    else
      {:error, Error.new(:invalid_option, "#{key} must be a keyword list")}
    end
  end
end
