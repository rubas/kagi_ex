defmodule KagiEx.MixProject do
  use Mix.Project

  @version "0.1.0"

  @spec project() :: keyword()
  def project do
    [
      app: :kagi_ex,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
      usage_rules: usage_rules()
    ]
  end

  @spec application() :: keyword()
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  @spec docs() :: keyword()
  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "usage-rules.md", "RELEASE.md"],
      source_url: "https://github.com/rubas/kagi_ex",
      homepage_url: "https://github.com/rubas/kagi_ex",
      groups_for_modules: [
        Search: [Kagi.Search, Kagi.SearchResult],
        Summarizer: [Kagi.Summary],
        Maps: [Kagi.Maps, Kagi.MapsResult, Kagi.MapsResult.Coordinates]
      ]
    ]
  end

  @spec description() :: String.t()
  defp description do
    "Typed Elixir client for Kagi Search, Summarizer, and Maps, built on Req."
  end

  @spec package() :: keyword()
  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/rubas/kagi_ex",
        "HexDocs" => "https://hexdocs.pm/kagi_ex",
        "Kagi" => "https://kagi.com"
      },
      files: ~w(lib mix.exs README.md CHANGELOG.md RELEASE.md usage-rules.md LICENSE*)
    ]
  end

  @spec usage_rules() :: keyword()
  defp usage_rules do
    [
      file: "AGENTS.md",
      usage_rules: [
        {~r/.*/, link: :markdown}
      ]
    ]
  end

  @spec deps() :: [tuple()]
  defp deps do
    [
      {:req, "~> 0.5"},
      {:lazy_html, "~> 0.1"},
      {:cloaked_req, "~> 0.3.2"},
      {:credo, "~> 1.7.18", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.11", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:usage_rules, "~> 1.2.4", only: [:dev], runtime: false}
    ]
  end
end
