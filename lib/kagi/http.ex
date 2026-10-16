defmodule Kagi.HTTP do
  @moduledoc false

  alias Kagi.Client
  alias Kagi.Error

  @type response :: %{status: pos_integer(), body: term()}

  # Redirects and retries are off by default: the session cookie must never
  # follow a cross-host redirect, and a 429 must not trigger hidden follow-up
  # requests. Both can be re-enabled per client via :req_options. The endpoint
  # URL and method merge last so configuration can never redirect a request
  # (and its session cookie) to another host.
  @spec get(Client.t(), String.t(), keyword()) :: {:ok, response()} | {:error, Error.t()}
  def get(%Client{} = client, url, options) when is_binary(url) and is_list(options) do
    request =
      [redirect: false, retry: false]
      |> Req.new()
      |> CloakedReq.attach()
      |> Req.merge(client.req_options)
      |> Req.merge(options)
      |> Req.merge(url: url, method: :get)

    with {:ok, %Req.Response{} = response} <-
           request |> Req.request() |> normalize_request_error() do
      handle_response(response, url)
    end
  end

  @spec normalize_request_error({:ok, Req.Response.t()} | {:error, Exception.t()}) ::
          {:ok, Req.Response.t()} | {:error, Error.t()}
  defp normalize_request_error({:ok, %Req.Response{} = response}), do: {:ok, response}

  defp normalize_request_error(
         {:error,
          %CloakedReq.AdapterError{error: %CloakedReq.Error{details: %{"reason" => reason}}} =
            exception}
       )
       when is_binary(reason) do
    {:error, Error.new(:request_failed, "#{Exception.message(exception)} (#{reason})")}
  end

  defp normalize_request_error({:error, exception}) do
    {:error, Error.new(:request_failed, Exception.message(exception))}
  end

  @spec handle_response(Req.Response.t(), String.t()) :: {:ok, response()} | {:error, Error.t()}
  defp handle_response(%Req.Response{status: status}, _url) when status in [401, 403] do
    {:error, unauthorized()}
  end

  defp handle_response(%Req.Response{status: 429}, _url),
    do: {:error, Error.new(:rate_limited, "rate limited")}

  defp handle_response(%Req.Response{status: status, body: body}, _url) when status in 200..299 do
    {:ok, %{status: status, body: body}}
  end

  defp handle_response(%Req.Response{status: status} = response, url) when status in 300..399 do
    case Req.Response.get_header(response, "location") do
      [location | _] -> handle_redirect(status, URI.merge(url, location))
      [] -> {:error, Error.new(:http_error, "HTTP #{status}")}
    end
  end

  defp handle_response(%Req.Response{status: status}, _url),
    do: {:error, Error.new(:http_error, "HTTP #{status}")}

  # Kagi redirects a request with an invalid or expired session to its
  # sign-up page instead of answering 401.
  @spec handle_redirect(pos_integer(), URI.t()) :: {:error, Error.t()}
  defp handle_redirect(_status, %URI{host: "kagi.com", path: "/welcome"}),
    do: {:error, unauthorized()}

  defp handle_redirect(status, location),
    do: {:error, Error.new(:http_error, "HTTP #{status} to #{location}")}

  @spec unauthorized() :: Error.t()
  defp unauthorized, do: Error.new(:unauthorized, "invalid or expired session token")
end
