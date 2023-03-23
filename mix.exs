defmodule Eslx.MixProject do
  use Mix.Project

  def project do
    [
      app: :eslx,
      version: "0.1.0",
      elixir: "~> 1.13",
      description: "freeswitch connector using esl.c",
      compilers: [:unifex, :bundlex] ++ Mix.compilers, # add unifex and bundlex to compilers
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
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]


  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:unifex, "~> 1.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ranch, "~> 2.1", only: [:dev, :test]}
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
