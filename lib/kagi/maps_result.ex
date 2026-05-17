defmodule Kagi.MapsResult do
  @moduledoc """
  A single Kagi Maps point-of-interest result.

  Returned in `Kagi.Maps.results`. Most fields are optional because Kagi Maps
  providers return different metadata.

  ## Fields

    * `:name` - place name.
    * `:address` - street address.
    * `:coordinates` - `Kagi.MapsResult.Coordinates` with latitude/longitude.
    * `:phone` - phone number in international format.
    * `:url` - website URL.
    * `:source` - upstream provider name.
    * `:id` - Kagi or upstream provider identifier.
    * `:rating` - average rating.
    * `:review_count` - number of reviews backing `:rating`.
    * `:price` - price tier string such as `"$"` or `"$$"`.
    * `:distance` - distance from `:ll`, when supplied.
    * `:hours_now` - open/closed indicator string.
    * `:types` - category tags.
    * `:links` - provider-specific links payload.
    * `:images` - image references payload.
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
