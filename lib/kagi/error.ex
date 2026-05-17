defmodule Kagi.Error do
  @moduledoc """
  Structured error returned by Kagi operations.

  The `:reason` field is stable for pattern matching. The `:message` field is
  intended for logs and user-visible diagnostics.
  """

  @type reason ::
          :missing_session_token
          | :invalid_option
          | :request_failed
          | :unauthorized
          | :rate_limited
          | :http_error
          | :blocked
          | :parse_error

  @type t :: %__MODULE__{reason: reason(), message: String.t()}

  defexception [:reason, :message]

  @doc """
  Builds a Kagi error with a stable reason and diagnostic message.
  """
  @spec new(reason(), String.t()) :: t()
  def new(reason, message) when is_atom(reason) and is_binary(message) do
    %__MODULE__{reason: reason, message: message}
  end
end
