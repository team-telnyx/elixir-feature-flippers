defmodule FeatureFlippers.MixProject do
  use Mix.Project

  @source_url "https://github.com/team-telnyx/elixir-feature-flippers"
  @version "1.0.0"

  def project do
    [
      app: :feature_flippers,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/team-telnyx/elixir-feature-flippers",
      description: description(),
      name: "FeatureFlippers",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Provides a mechanism to turn features on and off within an Elixir
    application.
    """
  end

  defp package do
    [
      maintainers: [
        "Guilherme Versiani <guilherme@telnyx.com>",
        "Marcus Vieira <marcus@telnyx.com>"
      ],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/team-telnyx/elixir-feature-flippers"},
      files: ~w"lib mix.exs README.md LICENSE"
    ]
  end

  defp docs do
  [
    main: "FeatureFlippers",
    source_ref: "v#{@version}",
    canonical: "https://hexdocs.pm/feature_flippers",
    source_url: @source_url
  ]
  end
end
