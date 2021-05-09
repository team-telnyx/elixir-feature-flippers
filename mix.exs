defmodule FeatureFlippers.MixProject do
  use Mix.Project

  def project do
    [
      app: :feature_flippers,
      version: "0.1.1",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/team-telnyx/elixir-feature-flippers",
      description: description()
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
    Easier management of feature flippers in Elixir.
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
end
