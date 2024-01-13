defmodule PhoenixBetterTable.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_better_table,
      version: "0.3.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A better table for Phoenix LiveView",
      package: package(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["test.watch": :test, cover: :test, ci: :test],
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.14", only: :test},
      {:floki, ">= 0.30.0", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:live_isolated_component, "~> 0.8.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:phoenix_live_view, ">= 0.18.17"}
    ]
  end

  def package do
    [
      files: ["lib", "mix.exs", "README.md"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mwhitworth/phoenix_better_table"}
    ]
  end

  def aliases do
    [
      ci: [
        "format --check-formatted",
        "credo --strict",
        "compile --warnings-as-errors --force",
        "test"
      ],
      cover: ["coveralls.html"]
    ]
  end
end
