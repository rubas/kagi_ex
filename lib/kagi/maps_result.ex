defmodule Kagi.MapsResult do
  @moduledoc """
  A single Kagi Maps point-of-interest result.

  Returned inside `Kagi.Maps.results` from `Kagi.maps/1..3`. Most fields except
  `:name` and `:coordinates` are optional and may be `nil` depending on the
  source. `:id` is the Kagi internal identifier when present, otherwise the
  upstream provider's identifier.

  ## Fields

    * `:name` - place name (always present).
    * `:address` - street address.
    * `:coordinates` - `Kagi.MapsResult.Coordinates` with latitude/longitude.
    * `:phone` - phone number in international format.
    * `:url` - website URL.
    * `:source` - upstream provider name (e.g. `"searchapiio"`).
    * `:id` - Kagi internal id (`id_k`), falling back to the upstream id.
    * `:rating` - average rating, typically `0.0..5.0`.
    * `:review_count` - number of reviews backing `:rating`.
    * `:price` - price tier string such as `"$"`, `"$$"`, `"$$$"`.
    * `:distance` - distance from `:ll` (when supplied), in the units
      Kagi returns.
    * `:hours_now` - open/closed indicator string.
    * `:types` - category tags (e.g. `["cafe"]`).
    * `:links` - raw JSON sub-object with provider-specific links.
    * `:images` - raw JSON sub-object with image references.
  """

  alias Kagi.MapsResult.Coordinates

  @typedoc "A single Maps point of interest."
  @type t :: %__MODULE__{
          name: String.t(),
          address: String.t() | nil,
          coordinates: Coordinates.t(),
          phone: String.t() | nil,
          url: String.t() | nil,
          source: String.t() | nil,
          id: String.t() | nil,
          rating: float() | nil,
          review_count: non_neg_integer() | nil,
          price: String.t() | nil,
          distance: float() | nil,
          hours_now: String.t() | nil,
          types: [String.t()] | nil,
          links: term() | nil,
          images: term() | nil
        }

  defstruct [
    :name,
    :address,
    :coordinates,
    :phone,
    :url,
    :source,
    :id,
    :rating,
    :review_count,
    :price,
    :distance,
    :hours_now,
    :types,
    :links,
    :images
  ]
end
