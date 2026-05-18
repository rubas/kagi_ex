defmodule Kagi.LiveTest do
  @moduledoc """
  Covers opt-in live Kagi requests through the public client API.

  These tests require a real Kagi session token. They verify that the current request wiring can reach Kagi, but they do
  not pin exact search result ordering or summary text.
  """

  use ExUnit.Case, async: false

  @moduletag :live

  setup do
    previous_session_token = Application.get_env(:kagi_ex, :session_token)

    on_exit(fn ->
      restore_env(:session_token, previous_session_token)
    end)

    Application.put_env(:kagi_ex, :session_token, live_session_token!())
    :ok
  end

  test "search returns typed results" do
    client = Kagi.new!()

    assert %Kagi.Search{results: [_ | _]} =
             Kagi.search!(client, "elixir req http client", lens: :programming, limit: 3)

    assert Enum.all?(Kagi.search!(client, "elixir lang", limit: 3).results, &search_result?/1)
  end

  test "summarize returns markdown" do
    client = Kagi.new!()

    assert %Kagi.Summary{summary: summary} =
             Kagi.summarize!(client, "https://www.rust-lang.org/learn")

    assert is_binary(summary)
    assert String.trim(summary) != ""
  end

  test "maps returns typed results for a geographic query" do
    client = Kagi.new!()

    assert %Kagi.Maps{results: [_ | _] = results} =
             Kagi.maps!(client, "coffee zurich", ll: "47.3769,8.5417", limit: 3)

    assert Enum.all?(results, &maps_result?/1)
  end

  defp restore_env(key, nil), do: Application.delete_env(:kagi_ex, key)
  defp restore_env(key, value), do: Application.put_env(:kagi_ex, key, value)

  defp search_result?(%Kagi.SearchResult{url: url, title: title, snippet: snippet}) do
    String.starts_with?(url, "http") and title != "" and is_binary(snippet)
  end

  defp maps_result?(%Kagi.MapsResult{
         name: name,
         coordinates: %Kagi.MapsResult.Coordinates{latitude: lat, longitude: lon}
       }) do
    is_binary(name) and name != "" and is_number(lat) and is_number(lon)
  end

  defp maps_result?(_other), do: false

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
         path = Path.join([xdg, "kagi", "session-token"]),
         {:ok, contents} <- File.read(path) do
      String.trim(contents)
    else
      _other -> nil
    end
  end
end
