defmodule Kagi.ClientTest do
  @moduledoc """
  Covers client configuration and session token resolution.

  It does not prove live authentication with Kagi; tests use explicit tokens.
  """

  use ExUnit.Case, async: false

  alias Kagi.Client
  alias Kagi.Error

  setup do
    keys = [:session_token, :transport, :cloaked_req_options, :req_options]
    previous = Map.new(keys, fn key -> {key, Application.get_env(:kagi_ex, key)} end)

    on_exit(fn ->
      Enum.each(keys, fn key ->
        case Map.fetch!(previous, key) do
          nil -> Application.delete_env(:kagi_ex, key)
          value -> Application.put_env(:kagi_ex, key, value)
        end
      end)
    end)

    Enum.each(keys, &Application.delete_env(:kagi_ex, &1))
  end

  test "builds req client with explicit token by default" do
    assert {:ok, %Client{session_token: "token", transport: :req}} =
             Kagi.new(session_token: " token ")
  end

  test "resolves token from application config" do
    Application.put_env(:kagi_ex, :session_token, "config-token")

    assert {:ok, %Client{session_token: "config-token"}} = Kagi.new()
  end

  test "explicit option overrides application config" do
    Application.put_env(:kagi_ex, :session_token, "config-token")

    assert {:ok, %Client{session_token: "explicit"}} = Kagi.new(session_token: "explicit")
  end

  test "transport and cloaked_req_options come from application config" do
    Application.put_env(:kagi_ex, :transport, :cloaked_req)
    Application.put_env(:kagi_ex, :cloaked_req_options, impersonate: :chrome_136)

    assert {:ok,
            %Client{
              transport: :cloaked_req,
              cloaked_req_options: [impersonate: :chrome_136]
            }} = Kagi.new(session_token: "token")
  end

  test "per-call :transport, :req_options, :cloaked_req_options are ignored" do
    Application.put_env(:kagi_ex, :transport, :cloaked_req)

    assert {:ok, %Client{transport: :cloaked_req, req_options: [], cloaked_req_options: []}} =
             Kagi.new(
               session_token: "token",
               transport: :req,
               req_options: [retry: false],
               cloaked_req_options: [impersonate: :chrome_136]
             )
  end

  test "returns structured error when no token exists" do
    assert {:error, %Error{reason: :missing_session_token, message: message}} = Kagi.new()
    assert message =~ "missing session token"
  end

  test "rejects explicit invalid token instead of falling back to config" do
    Application.put_env(:kagi_ex, :session_token, "config-token")

    for invalid <- [nil, "", "   ", 123, :token] do
      assert {:error, %Error{reason: :missing_session_token, message: message}} =
               Kagi.new(session_token: invalid)

      assert message =~ "invalid :session_token"
    end
  end
end
