defmodule Kagi.MapsTest do
  @moduledoc """
  Covers parsing Kagi Maps JSON fixtures, option validation, and client-side sorting.

  It does not perform live Kagi requests.
  """

  use ExUnit.Case, async: true

  alias Kagi.Error
  alias Kagi.Maps
  alias Kagi.MapsResult

  test "parses maps results fixture" do
    {:ok, json} = "test/fixtures/maps/search.json" |> File.read!() |> JSON.decode()

    assert {:ok, output} = Maps.parse(json, 1)
    assert length(output.results) == 1

    [first] = output.results
    assert first.name == "Example Coffee"
    assert first.address == "Example Street 1"
    assert first.phone == "+41 44 000 00 00"
    assert first.rating == 4.7
    assert first.review_count == 477
    assert first.price == "$$"
    assert first.coordinates.latitude == 47.3726576
    assert first.coordinates.longitude == 8.5262939
    assert first.id == "kagi-id"
    assert first.types == ["cafe"]
  end

  test "second result with sparse fields parses" do
    {:ok, json} = "test/fixtures/maps/search.json" |> File.read!() |> JSON.decode()

    assert {:ok, output} = Maps.parse(json, 5)
    assert [_first, second] = output.results
    assert second.name == "Second Coffee"
    assert second.address == "Example Street 2"
    assert second.rating == nil
    assert second.id == nil
    assert second.coordinates.latitude == 47.37
  end

  test "rejects invalid sort option before any network call" do
    client = %Kagi.Client{session_token: "token"}

    assert {:error, %Error{reason: :invalid_option, message: message}} =
             Kagi.maps(client, "coffee", sort: :bogus)

    assert message =~ "invalid maps sort"
  end

  test "rejects invalid coordinate format" do
    client = %Kagi.Client{session_token: "token"}

    assert {:error, %Error{reason: :invalid_option, message: message}} =
             Kagi.maps(client, "coffee", ll: "not-a-coord")

    assert message =~ "LAT,LON"
  end

  test "rejects coordinate outside valid range" do
    client = %Kagi.Client{session_token: "token"}

    assert {:error, %Error{reason: :invalid_option, message: message}} =
             Kagi.maps(client, "coffee", ll: "100.0,8.5")

    assert message =~ "latitude"
  end

  test "rejects degenerate bounding box" do
    client = %Kagi.Client{session_token: "token"}

    assert {:error, %Error{reason: :invalid_option, message: message}} =
             Kagi.maps(client, "coffee", bbox: "8.5,47.3,8.5,47.4")

    assert message =~ "WEST and EAST"
  end

  test "rejects empty query" do
    client = %Kagi.Client{session_token: "token"}

    assert {:error, %Error{reason: :invalid_option, message: message}} = Kagi.maps(client, "   ")
    assert message =~ "query"
  end

  test "rejects queries that are not strings or lists of strings" do
    client = %Kagi.Client{session_token: "token"}

    for query <- [~c"coffee", [limit: 5], ["coffee", :zurich], ["coffee" | "zurich"]] do
      assert {:error, %Error{reason: :invalid_option, message: message}} =
               Kagi.maps(client, query)

      assert message =~ "query must be a string or a list of strings"
    end
  end

  test "rejects invalid :limit before any network call" do
    test_pid = self()

    adapter = fn request ->
      send(test_pid, :network)
      {request, Req.Response.new(status: 200, body: %{"pois" => []})}
    end

    client = %Kagi.Client{session_token: "token", req_options: [adapter: adapter]}

    assert {:error, %Error{reason: :invalid_option, message: message}} =
             Kagi.maps(client, "coffee", limit: "5")

    assert message =~ ":limit"
    refute_received :network
  end

  test "rejects pois arrays with entries that are not objects" do
    assert {:error, %Error{reason: :parse_error, message: message}} =
             Maps.parse(%{"pois" => [%{"name" => "ok"}, nil]}, 10)

    assert message =~ "not objects"
  end

  test "reports missing pois with top-level keys only" do
    assert {:error, %Error{reason: :parse_error, message: message}} =
             Maps.parse(%{"places" => [], "status" => "ok"}, 10)

    assert message =~ ~s(top-level keys: ["places", "status"])
  end

  test "reports a pois value that is not an array as a type error" do
    assert {:error, %Error{reason: :parse_error, message: message}} =
             Maps.parse(%{"pois" => %{}}, 10)

    assert message =~ "'pois' must be an array"
  end

  test "normalizes drift-prone scalars to nil instead of crashing sorts" do
    json = %{
      "pois" => [
        %{
          "name" => "drifted",
          "price" => 2,
          "rating" => "4.7",
          "reviewCount" => "12",
          "distance" => "near",
          "hours_now" => 1
        },
        %{
          "name" => "typed",
          "price" => "$$",
          "rating" => 4.1,
          "reviewCount" => 3,
          "distance" => 1.2,
          "hours_now" => "Open"
        },
        %{"name" => "integer rating", "rating" => 4, "distance" => 2}
      ]
    }

    assert {:ok, output} = Maps.parse(json, 10)
    assert [drifted, typed, integer_rating] = output.results

    assert %MapsResult{price: nil, rating: nil, review_count: nil, distance: nil, hours_now: nil} =
             drifted

    assert %MapsResult{
             price: "$$",
             rating: 4.1,
             review_count: 3,
             distance: 1.2,
             hours_now: "Open"
           } = typed

    assert %MapsResult{rating: 4.0, distance: 2.0} = integer_rating

    sorted = Maps.sort_results(output.results, :price, nil)
    assert Enum.map(sorted, & &1.name) == ["typed", "drifted", "integer rating"]
  end

  test "sorts by rating desc by default and pushes missing ratings last" do
    results = [
      %MapsResult{name: "low", rating: 2.0},
      %MapsResult{name: "missing", rating: nil},
      %MapsResult{name: "high", rating: 4.7}
    ]

    sorted = Maps.sort_results(results, :rating, nil)
    assert Enum.map(sorted, & &1.name) == ["high", "low", "missing"]
  end

  test "sorts by distance asc by default" do
    results = [
      %MapsResult{name: "far", distance: 5.0},
      %MapsResult{name: "near", distance: 1.0},
      %MapsResult{name: "missing", distance: nil}
    ]

    sorted = Maps.sort_results(results, :distance, nil)
    assert Enum.map(sorted, & &1.name) == ["near", "far", "missing"]
  end

  test "sorts by price using string length" do
    results = [
      %MapsResult{name: "expensive", price: "$$$"},
      %MapsResult{name: "cheap", price: "$"},
      %MapsResult{name: "medium", price: "$$"}
    ]

    sorted = Maps.sort_results(results, :price, nil)
    assert Enum.map(sorted, & &1.name) == ["cheap", "medium", "expensive"]
  end

  test "explicit order overrides the default" do
    results = [
      %MapsResult{name: "near", distance: 1.0},
      %MapsResult{name: "far", distance: 5.0}
    ]

    sorted = Maps.sort_results(results, :distance, :desc)
    assert Enum.map(sorted, & &1.name) == ["far", "near"]
  end

  test "relevance sort is a no-op" do
    results = [
      %MapsResult{name: "first", rating: 1.0},
      %MapsResult{name: "second", rating: 5.0}
    ]

    assert Maps.sort_results(results, :relevance, nil) == results
  end
end
