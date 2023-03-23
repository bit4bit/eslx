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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:unifex, "~> 1.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
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
