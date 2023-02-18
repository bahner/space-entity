defmodule MyspaceObject.MixProject do
  @moduledoc """
  Mix project for MyspaceObject
  """
  use Mix.Project

  def project do
    [
      app: :myspace_object,
      version: "0.1.0-alpha.2",
      elixir: "~> 1.14",
      name: "Myspace Object",
      deps: deps(),
      description: "Generic actor model object for uses in IPFS",
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/bahner/myspace-object"
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
      {:nanoid, "~> 2.0"},
      {:ex_crypto, "~> 0.10.0"},
      {:myspace_ipfs, "~> 0.2.0-alpha"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:excoveralls, "~> 0.15", only: :test, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Lars Bahner"],
      licenses: ["GNU GPLv3"],
      links: %{"GitHub" => "https://github.com/bahner/myspace-object"}
    ]
  end
end
