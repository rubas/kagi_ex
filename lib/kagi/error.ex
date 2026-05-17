defmodule Kagi.Error do
  @moduledoc """
  Structured error returned by every Kagi operation.

  `Kagi.Error` is both a struct and an exception. Non-bang functions return it
  in `{:error, error}`; bang functions raise it.

  The `:reason` atom is stable for pattern matching; the `:message` string is
  diagnostic text and may change between releases.

  ## Reasons

    * `:missing_session_token` - no valid session token is configured.
    * `:invalid_option` - an option failed client-side validation.
    * `:request_failed` - the HTTP request failed before receiving a response.
    * `:unauthorized` - Kagi returned HTTP 401 or 403.
    * `:rate_limited` - Kagi returned HTTP 429.
    * `:http_error` - Kagi returned an unexpected non-2xx status.
    * `:blocked` - Kagi returned a CAPTCHA or challenge page.
    * `:parse_error` - a response could not be parsed.
  """

  @typedoc "Stable, machine-readable reason returned in `%Kagi.Error{}`."
  @type reason ::
          :missing_session_token
          | :invalid_option
          | :request_failed
          | :unauthorized
          | :rate_limited
          | :http_error
          | :blocked
          | :parse_error

  @typedoc "A `Kagi.Error` value."
  @type t :: %__MODULE__{reason: reason(), message: String.t()}

  defexception [:reason, :message]

  @doc """
  Builds a `Kagi.Error` with a stable reason and diagnostic message.

  Application code usually receives these values from `Kagi` calls rather than
  constructing them directly.

  ## Examples

      Kagi.Error.new(:invalid_option, "limit must be a non-negative integer")
      #=> %Kagi.Error{reason: :invalid_option, message: "limit must be a non-negative integer"}
  """
  @spec new(reason(), String.t()) :: t()
  def new(reason, message) when is_atom(reason) and is_binary(message) do
    %__MODULE__{reason: reason, message: message}
  end
end
