defmodule Kagi.HTTP do
  @moduledoc false

  alias Kagi.Client
  alias Kagi.Error

  @type response :: %{status: pos_integer(), body: term()}

  @spec get(Client.t(), String.t(), keyword()) :: {:ok, response()} | {:error, Error.t()}
  def get(%Client{} = client, url, options) when is_binary(url) and is_list(options) do
    request =
      client.req_options
      |> Keyword.put(:url, url)
      |> Keyword.put(:method, :get)
      |> Req.new()
      |> Req.merge(options)

    with {:ok, request} <- attach_transport(request, client),
         {:ok, %Req.Response{status: status, body: body}} <-
           request |> Req.request() |> normalize_request_error() do
      handle_status(status, body)
    end
  end

  @spec attach_transport(Req.Request.t(), Client.t()) ::
          {:ok, Req.Request.t()} | {:error, Error.t()}
  defp attach_transport(%Req.Request{} = request, %Client{transport: :req}), do: {:ok, request}

  defp attach_transport(%Req.Request{} = request, %Client{
         transport: :cloaked_req,
         cloaked_req_options: options
       }) do
    if Code.ensure_loaded?(CloakedReq) do
      {:ok, CloakedReq.attach(request, options)}
    else
      {:error,
       Error.new(
         :invalid_option,
         "transport :cloaked_req requires the :cloaked_req dependency; add {:cloaked_req, \"~> 0.3\"} to your deps"
       )}
    end
  end

  @spec normalize_request_error({:ok, Req.Response.t()} | {:error, Exception.t()}) ::
          {:ok, Req.Response.t()} | {:error, Error.t()}
  defp normalize_request_error({:ok, %Req.Response{} = response}), do: {:ok, response}

  defp normalize_request_error({:error, exception}) do
    {:error, Error.new(:request_failed, Exception.message(exception))}
  end

  @spec handle_status(pos_integer(), term()) :: {:ok, response()} | {:error, Error.t()}
  defp handle_status(status, _body) when status in [401, 403] do
    {:error, Error.new(:unauthorized, "invalid or expired session token")}
  end

  defp handle_status(429, _body), do: {:error, Error.new(:rate_limited, "rate limited")}

  defp handle_status(status, body) when status >= 200 and status <= 299 do
    {:ok, %{status: status, body: body}}
  end

  defp handle_status(status, _body), do: {:error, Error.new(:http_error, "HTTP #{status}")}
end
