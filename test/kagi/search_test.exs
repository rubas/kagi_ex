defmodule Kagi.SearchTest do
  @moduledoc """
  Covers parsing Kagi HTML search fixtures and validating important search option contracts.

  It does not perform live Kagi requests. Fixtures are simplified copies of the HTML shapes parsed by the Rust
  implementation this library ports.
  """

  use ExUnit.Case, async: true

  alias Kagi.Error
  alias Kagi.Search

  test "parses standard results fixture" do
    html = File.read!("test/fixtures/search/basic.html")

    assert {:ok, output} = Search.parse(html, 2)
    assert length(output.results) == 2
    assert hd(output.results).title == "Example One"
    assert hd(output.results).url == "https://example.com/1"
    assert hd(output.results).snippet == "First result description."
    assert Enum.at(output.results, 1).title == "Example Two"
    assert output.related == ["related term one", "related term two"]
  end

  test "parses grouped results fixture" do
    html = File.read!("test/fixtures/search/grouped.html")

    assert {:ok, output} = Search.parse(html, 10)
    assert length(output.results) == 2
    assert hd(output.results).title == "Grouped One"
    assert hd(output.results).url == "https://grouped.com/1"
    assert hd(output.results).snippet == "Grouped description one."
  end

  test "detects CAPTCHA fixture" do
    html = File.read!("test/fixtures/search/captcha.html")

    assert {:error, %Error{reason: :blocked, message: message}} = Search.parse(html, 10)
    assert message =~ "CAPTCHA"
  end

  test "rejects 200 responses without recognizable search structure" do
    html = "<html><body><h1>Maintenance</h1><p>Be right back.</p></body></html>"

    assert {:error, %Error{reason: :parse_error, message: message}} = Search.parse(html, 10)
    assert message =~ "no recognizable results structure"
  end

  test "rejects incompatible time and date range options before network requests" do
    client = Kagi.new!(session_token: "token")

    assert {:error, %Error{reason: :invalid_option, message: message}} =
             Kagi.search(client, "rust", time: :week, from: "2026-03-01")

    assert message =~ ":time"
  end
end
