defmodule Kagi.SearchResult do
  @moduledoc """
  A single Kagi search result.

  Returned in `Kagi.Search.results`.

  ## Fields

    * `:url` - absolute destination URL.
    * `:title` - link title text.
    * `:snippet` - result description; empty when Kagi returns none.
  """

  @typedoc "A single search result row."
  @type t :: %__MODULE__{url: String.t(), title: String.t(), snippet: String.t()}

  defstruct [:url, :title, :snippet]
end
