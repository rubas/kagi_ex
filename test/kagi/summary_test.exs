defmodule Kagi.SummaryTest do
  @moduledoc """
  Covers parsing Kagi summarizer stream fixtures.

  It does not perform live Kagi requests. Fixtures are simplified stream payloads copied from the Rust port's parser
  tests.
  """

  use ExUnit.Case, async: true

  alias Kagi.Error
  alias Kagi.Summary

  test "parses summary stream fixture" do
    body = fixture("stream.txt")

    assert {:ok, output} = Summary.parse_stream(body)
    assert output.summary == "# Summary\nThis is the summary."
  end

  test "parses output_data markdown fallback" do
    body = fixture("fallback.txt")

    assert {:ok, output} = Summary.parse_stream(body)
    assert output.summary == "Fallback content."
  end

  test "falls back to output_data markdown when md is an empty string" do
    body = fixture("empty_md_fallback.txt")

    assert {:ok, output} = Summary.parse_stream(body)
    assert output.summary == "Real content."
  end

  test "reports summary error state as :summarizer_error" do
    body = fixture("error.txt")

    assert {:error, %Error{reason: :summarizer_error, message: message}} =
             Summary.parse_stream(body)

    assert message =~ "sorry"
  end

  test "reports a done state without any markdown as :parse_error" do
    body = ~s(final:{"state":"done"})

    assert {:error, %Error{reason: :parse_error, message: message}} = Summary.parse_stream(body)
    assert message =~ "Missing markdown"
  end

  test "reports an empty summary as :summarizer_error" do
    body = ~s(final:{"state":"done","md":""})

    assert {:error, %Error{reason: :summarizer_error, message: message}} =
             Summary.parse_stream(body)

    assert message =~ "Empty summary"
  end

  describe "request timeout" do
    defp client_capturing_timeout(test_pid, req_options) do
      adapter = fn request ->
        send(test_pid, {:receive_timeout, request.options[:receive_timeout]})
        body = ~s(final:{"state":"done","md":"# Summary"})
        {request, Req.Response.new(status: 200, body: body)}
      end

      %Kagi.Client{session_token: "token", req_options: [adapter: adapter] ++ req_options}
    end

    test "defaults to 60 seconds" do
      client = client_capturing_timeout(self(), [])

      assert {:ok, _summary} = Kagi.summarize(client, "https://example.com")
      assert_received {:receive_timeout, 60_000}
    end

    test "client receive_timeout overrides the summarizer default" do
      client = client_capturing_timeout(self(), receive_timeout: 20_000)

      assert {:ok, _summary} = Kagi.summarize(client, "https://example.com")
      assert_received {:receive_timeout, 20_000}
    end

    test ":timeout overrides the client receive_timeout" do
      client = client_capturing_timeout(self(), receive_timeout: 20_000)

      assert {:ok, _summary} = Kagi.summarize(client, "https://example.com", timeout: 5_000)
      assert_received {:receive_timeout, 5_000}
    end

    test "rejects an invalid :timeout before any request" do
      client = client_capturing_timeout(self(), [])

      assert {:error, %Error{reason: :invalid_option, message: message}} =
               Kagi.summarize(client, "https://example.com", timeout: :infinity)

      assert message =~ ":timeout"
      refute_received {:receive_timeout, _timeout}
    end
  end

  defp fixture(name) do
    "test/fixtures/summary/#{name}"
    |> File.read!()
    |> String.replace("[NUL]", <<0>>)
  end
end
