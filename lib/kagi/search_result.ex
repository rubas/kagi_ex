defmodule Kagi.SearchResult do
  @moduledoc """
  Single Kagi search result.
  """

  @type t :: %__MODULE__{url: String.t(), title: String.t(), snippet: String.t()}

  defstruct [:url, :title, :snippet]
end
