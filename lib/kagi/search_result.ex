defmodule Kagi.SearchResult do
  @moduledoc """
  A single Kagi search result.

  Returned inside `Kagi.Search.results` from `Kagi.search/2` and
  `Kagi.search/3`.

  ## Fields

    * `:url` - absolute destination URL.
    * `:title` - link title text.
    * `:snippet` - description text shown under the link; empty string when
      Kagi did not return one.
  """

  @typedoc "A single search result row."
  @type t :: %__MODULE__{url: String.t(), title: String.t(), snippet: String.t()}

  defstruct [:url, :title, :snippet]
end
