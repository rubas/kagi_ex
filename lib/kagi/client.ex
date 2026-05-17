defmodule Kagi.Client do
  @moduledoc """
  Reusable Kagi client configuration.

  A client carries the resolved session token, the HTTP transport, and
  transport-specific options. Building a client performs no network I/O - the
  session token is checked for presence only.

  Use `Kagi.new/1` (the canonical entry point) or `Kagi.Client.new/1` directly.
  Clients are immutable; build once at application start and reuse for every
  request to avoid repeating token resolution.

  Only `:session_token` is accepted per call. `:transport`, `:req_options`,
  and `:cloaked_req_options` are read from application config so the choice
  is environment-wide and call sites stay focused on the query itself.

  ## Fields

    * `:session_token` - Kagi session token string.
    * `:transport` - `:req` (default) or `:cloaked_req`. Configured via
      `Application.put_env(:kagi_ex, :transport, ...)`.
    * `:req_options` - keyword list merged into every `Req` request.
      Configured via `Application.put_env(:kagi_ex, :req_options, ...)`.
    * `:cloaked_req_options` - keyword list passed to `CloakedReq.attach/2`
      when `:transport` is `:cloaked_req`. Configured via
      `Application.put_env(:kagi_ex, :cloaked_req_options, ...)`.
  """

  alias Kagi.Error

  @typedoc "HTTP transport selected for outbound Kagi requests."
  @type transport :: :req | :cloaked_req

  @typedoc "A configured Kagi client."
  @type t :: %__MODULE__{
          session_token: String.t(),
          transport: transport(),
          req_options: keyword(),
          cloaked_req_options: keyword()
        }

  defstruct [:session_token, :transport, req_options: [], cloaked_req_options: []]

  @doc """
  Builds a `%Kagi.Client{}` from `options`.

  See `Kagi.new/1` for the full list of supported options, defaults, and the
  application-config fallback. Returns `{:ok, client}` on success or
  `{:error, %Kagi.Error{}}` for an invalid or missing session token,
  an unsupported `:transport`, or a non-keyword `:req_options` /
  `:cloaked_req_options`.

  ## Examples

      {:ok, client} = Kagi.Client.new(session_token: "abc")
      {:error, %Kagi.Error{reason: :missing_session_token}} = Kagi.Client.new()
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(options \\ []) when is_list(options) do
    with {:ok, session_token} <- Kagi.SessionToken.resolve(options),
         {:ok, transport} <- validate_transport(configured(:transport, :req)),
         {:ok, req_options} <- validate_keyword_option(:req_options),
         {:ok, cloaked_req_options} <- validate_keyword_option(:cloaked_req_options) do
      {:ok,
       %__MODULE__{
         session_token: session_token,
         transport: transport,
         req_options: req_options,
         cloaked_req_options: cloaked_req_options
       }}
    end
  end

  @doc """
  Same as `new/1` but raises `Kagi.Error` on failure.
  """
  @spec new!(keyword()) :: t()
  def new!(options \\ []) do
    case new(options) do
      {:ok, client} -> client
      {:error, %Error{} = error} -> raise error
    end
  end

  @spec configured(atom(), term()) :: term()
  defp configured(key, default) do
    Application.get_env(:kagi_ex, key, default)
  end

  @spec validate_transport(term()) :: {:ok, transport()} | {:error, Error.t()}
  defp validate_transport(transport) when transport in [:req, :cloaked_req], do: {:ok, transport}

  defp validate_transport(transport) do
    {:error,
     Error.new(
       :invalid_option,
       "transport must be :req or :cloaked_req, got: #{inspect(transport)}"
     )}
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
