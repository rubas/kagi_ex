defmodule Kagi.Client do
  @moduledoc """
  Reusable Kagi client configuration.

  A client contains the resolved session token, the request transport, and
  transport-specific options. It performs no network request when built.

  Only `:session_token` is accepted per call. `:transport`, `:req_options`,
  and `:cloaked_req_options` are read from application config so the choice
  is environment-wide and call sites stay focused on the query itself.
  """

  alias Kagi.Error

  @type transport :: :req | :cloaked_req

  @type t :: %__MODULE__{
          session_token: String.t(),
          transport: transport(),
          req_options: keyword(),
          cloaked_req_options: keyword()
        }

  defstruct [:session_token, :transport, req_options: [], cloaked_req_options: []]

  @doc """
  Builds a `%Kagi.Client{}` with a resolved session token.

  See `Kagi.new/1` for supported options and token lookup order.
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
  Builds a `%Kagi.Client{}` or raises `Kagi.Error`.
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
