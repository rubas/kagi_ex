defmodule Kagi.Error do
  @moduledoc """
  Structured error returned by every Kagi operation.

  `Kagi.Error` is both a struct and an exception, so it can be returned in an
  `{:error, _}` tuple or raised directly by the `!`-suffixed API.

  The `:reason` atom is stable for pattern matching; the `:message` string is
  intended for logs and user-visible diagnostics and may change between
  releases.

  ## Reasons

    * `:missing_session_token` - no session token was provided or it was
      invalid (empty / non-binary).
    * `:invalid_option` - a user-supplied option failed validation
      (unknown lens, malformed coordinate, conflicting time/date range, etc.).
    * `:request_failed` - the HTTP request raised at the transport layer
      (DNS, TLS, timeout).
    * `:unauthorized` - Kagi returned HTTP 401 or 403; typically an
      expired session token.
    * `:rate_limited` - Kagi returned HTTP 429.
    * `:http_error` - Kagi returned an unexpected non-2xx status.
    * `:blocked` - the search response was a CAPTCHA or challenge page
      rather than results.
    * `:parse_error` - the response was reached but could not be parsed
      (malformed HTML, missing JSON keys, empty stream chunks).
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

  Used internally by `Kagi` to construct errors. Application code typically
  pattern-matches on the result of a `Kagi.*` call rather than calling
  `new/2` directly.

  ## Examples

      Kagi.Error.new(:invalid_option, "limit must be a non-negative integer")
      #=> %Kagi.Error{reason: :invalid_option, message: "limit must be a non-negative integer"}
  """
  @spec new(reason(), String.t()) :: t()
  def new(reason, message) when is_atom(reason) and is_binary(message) do
    %__MODULE__{reason: reason, message: message}
  end
end
