defmodule Kagi.ClientTest do
  @moduledoc """
  Covers client configuration and session token resolution.

  It does not prove live authentication with Kagi; tests use configured tokens.
  """

  use ExUnit.Case, async: false

  alias Kagi.Client
  alias Kagi.Error

  setup do
    keys = [:session_token, :req_options]
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

  test "resolves token from application config" do
    Application.put_env(:kagi_ex, :session_token, "config-token")

    assert {:ok, %Client{session_token: "config-token"}} = Kagi.new()
  end

  test "req_options come from application config" do
    Application.put_env(:kagi_ex, :session_token, "token")
    Application.put_env(:kagi_ex, :req_options, receive_timeout: 10_000)

    assert {:ok, %Client{req_options: [receive_timeout: 10_000]}} = Kagi.new()
  end

  test "returns structured error when no token exists" do
    assert {:error, %Error{reason: :missing_session_token, message: message}} = Kagi.new()
    assert message =~ "missing session token"
  end

  test "rejects invalid configured tokens" do
    for invalid <- [nil, "", "   ", 123, :token] do
      if is_nil(invalid) do
        Application.delete_env(:kagi_ex, :session_token)
      else
        Application.put_env(:kagi_ex, :session_token, invalid)
      end

      assert {:error, %Error{reason: :missing_session_token, message: message}} =
               Kagi.new()

      assert message =~ "missing session token"
    end
  end
end
