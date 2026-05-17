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

  test "reports summary error state" do
    body = fixture("error.txt")

    assert {:error, %Error{reason: :parse_error, message: message}} = Summary.parse_stream(body)
    assert message =~ "sorry"
  end

  defp fixture(name) do
    "test/fixtures/summary/#{name}"
    |> File.read!()
    |> String.replace("[NUL]", <<0>>)
  end
end
