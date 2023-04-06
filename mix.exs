defmodule Eslx.MixProject do
  use Mix.Project

  def project do
    [
      app: :eslx,
      version: "0.1.1",
      elixir: "~> 1.13",
      description: "freeswitch connector using esl.c",
      # add unifex and bundlex to compilers
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixir_options: [
        warnings_as_errors: true
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ranch]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:rustler, "~> 0.27.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:benchee, "~> 1.1", only: [:dev, :test]},
      {:ranch, "~> 2.1", only: [:dev, :test]},
      {:switchx, "~> 0.1.1", only: [:dev, :test]},
      {:elixir_mod_event, "~> 0.0.6", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bit4bit/eslx"},
      files: ~w(lib c_src bundlex.exs mix.exs README.md LICENSE)
    ]
  end
end
