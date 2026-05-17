defmodule Kagi.Client do
  @moduledoc """
  Reusable Kagi client configuration.

  A client carries the resolved session token and request options. Building a
  client performs no network I/O - the session token is checked for presence
  only.

  Use `Kagi.new/0` (the canonical entry point) or `Kagi.Client.new/0` directly.
  Clients are immutable; build once at application start and reuse for every
  request to avoid repeating token resolution.

  The session token and `:req_options` are read from application config so
  call sites stay focused on the query itself.

  ## Fields

    * `:session_token` - Kagi session token string.
    * `:req_options` - keyword list merged into every `Req` request.
      Configured via `Application.put_env(:kagi_ex, :req_options, ...)`.
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

  See `Kagi.new/0` for the full list of supported config, defaults, and the
  application-config fallback. Returns `{:ok, client}` on success or
  `{:error, %Kagi.Error{}}` for an invalid or missing session token,
  or a non-keyword `:req_options`.

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
  Same as `new/0` but raises `Kagi.Error` on failure.
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
