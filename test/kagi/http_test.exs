defmodule Kagi.HTTPTest do
  @moduledoc """
  Covers transport behavior with a fake Req adapter injected through `:req_options`.

  It does not perform live Kagi requests.
  """

  use ExUnit.Case, async: true

  alias Kagi.Client
  alias Kagi.Error
  alias Kagi.HTTP

  @url "https://kagi.com/html/search"

  defp client(req_options), do: %Client{session_token: "token", req_options: req_options}

  defp counting_adapter(test_pid, response) do
    fn request ->
      send(test_pid, {:request, request.url})
      {request, response}
    end
  end

  test "accepts CloakedReq adapter options through :req_options" do
    adapter = counting_adapter(self(), Req.Response.new(status: 200, body: "ok"))
    client = client(impersonate: :chrome_136, adapter: adapter)

    assert {:ok, %{status: 200, body: "ok"}} = HTTP.get(client, @url, [])
    assert_received {:request, _url}
  end

  test ":req_options cannot redirect requests to another host" do
    test_pid = self()

    adapter = fn request ->
      send(test_pid, {:sent, request.url, request.method})
      {request, Req.Response.new(status: 200, body: "ok")}
    end

    client = client(adapter: adapter, url: "https://attacker.example/", method: :delete)

    assert {:ok, %{status: 200}} = HTTP.get(client, @url, [])
    assert_received {:sent, url, :get}
    assert URI.to_string(url) =~ "kagi.com"
  end

  test "per-call options override client :req_options" do
    adapter = fn request -> {request, Req.Response.new(status: 200, body: "client adapter")} end
    override = fn request -> {request, Req.Response.new(status: 200, body: "call adapter")} end
    client = client(adapter: adapter)

    assert {:ok, %{body: "call adapter"}} = HTTP.get(client, @url, adapter: override)
  end

  test "does not retry a 429 and reports :rate_limited after one attempt" do
    adapter = counting_adapter(self(), Req.Response.new(status: 429))
    client = client(adapter: adapter)

    assert {:error, %Error{reason: :rate_limited}} = HTTP.get(client, @url, [])
    assert_received {:request, _url}
    refute_received {:request, _url}
  end

  test ":req_options can opt back into Req retries" do
    adapter = counting_adapter(self(), Req.Response.new(status: 429))

    client =
      client(adapter: adapter, retry: :safe_transient, retry_delay: 0, retry_log_level: false)

    assert {:error, %Error{reason: :rate_limited}} = HTTP.get(client, @url, [])

    for _attempt <- 1..4, do: assert_received({:request, _url})
    refute_received {:request, _url}
  end

  test "does not follow redirects and maps a 302 to :http_error" do
    response =
      Req.Response.new(status: 302, headers: %{"location" => ["https://elsewhere.example/"]})

    client = client(adapter: counting_adapter(self(), response))

    assert {:error, %Error{reason: :http_error, message: "HTTP 302"}} = HTTP.get(client, @url, [])

    assert_received {:request, _url}
    refute_received {:request, _url}
  end

  test "transport failures keep the adapter's failure reason in the message" do
    error =
      CloakedReq.Error.new(:transport_error, "request execution failed", %{
        "reason" => "connection timed out"
      })

    adapter = fn request -> {request, CloakedReq.AdapterError.exception(error)} end
    client = client(adapter: adapter)

    assert {:error, %Error{reason: :request_failed, message: message}} =
             HTTP.get(client, @url, [])

    assert message == "transport_error: request execution failed (connection timed out)"
  end

  test "transport failures without details still report the exception message" do
    adapter = fn request ->
      {request, CloakedReq.AdapterError.exception("request execution failed")}
    end

    client = client(adapter: adapter)

    assert {:error, %Error{reason: :request_failed, message: "request execution failed"}} =
             HTTP.get(client, @url, [])
  end
end
