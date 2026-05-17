defmodule Kagi.MapsResult.Coordinates do
  @moduledoc """
  WGS-84 latitude/longitude pair attached to a `Kagi.MapsResult`.

  ## Fields

    * `:latitude` - degrees north, `-90.0..90.0`.
    * `:longitude` - degrees east, `-180.0..180.0`.
  """

  @typedoc "Latitude/longitude pair in WGS-84 degrees."
  @type t :: %__MODULE__{latitude: float(), longitude: float()}

  defstruct [:latitude, :longitude]
end
