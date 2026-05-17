defmodule Kagi.LiveTest do
  @moduledoc """
  Covers opt-in live Kagi requests through the public client API.

  These tests require a real Kagi session token. They verify that the current request wiring can reach Kagi, but they do
  not pin exact search result ordering or summary text.
  """

  use ExUnit.Case, async: false

  @moduletag :live

  setup do
    {:ok, session_token: live_session_token!()}
  end

  test "search returns typed results with normal Req transport", %{session_token: token} do
    client = Kagi.new!(session_token: token, transport: :req)

    assert %Kagi.Search{results: [_ | _]} =
             Kagi.search!(client, "elixir req http client", lens: :programming, limit: 3)

    assert Enum.all?(Kagi.search!(client, "elixir lang", limit: 3).results, &search_result?/1)
  end

  test "search returns typed results with CloakedReq transport", %{session_token: token} do
    client =
      Kagi.new!(
        session_token: token,
        transport: :cloaked_req,
        cloaked_req_options: [impersonate: :chrome_136]
      )

    assert %Kagi.Search{results: [_ | _]} = search = Kagi.search!(client, "elixir lang", limit: 3)
    assert Enum.all?(search.results, &search_result?/1)
  end

  test "summarize returns markdown through normal Req transport", %{session_token: token} do
    client = Kagi.new!(session_token: token, transport: :req)

    assert %Kagi.Summary{summary: summary} =
             Kagi.summarize!(client, "https://www.rust-lang.org/learn")

    assert is_binary(summary)
    assert String.trim(summary) != ""
  end

  defp search_result?(%Kagi.SearchResult{url: url, title: title, snippet: snippet}) do
    String.starts_with?(url, "http") and title != "" and is_binary(snippet)
  end

  defp live_session_token! do
    token = System.get_env("KAGI_SESSION_TOKEN") || read_xdg_token()

    token ||
      flunk("""
      Live tests require a Kagi session token. Set KAGI_SESSION_TOKEN or store one in \
      $XDG_CONFIG_HOME/kagi/session-token.\
      """)
  end

  defp read_xdg_token do
    with xdg when is_binary(xdg) <- System.get_env("XDG_CONFIG_HOME"),
         {:ok, contents} <- File.read(Path.join([xdg, "kagi", "session-token"])) do
      String.trim(contents)
    else
      _other -> nil
    end
  end
end
