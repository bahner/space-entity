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
      extra_applications: [:logger],
      mod: {MyspaceObject.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_crypto, "~> 0.10.0"},
      {:ex_ipfs, "~> 0.1.4"},
      {:ex_ipfs_ipld, "~> 0.0.1"},
      {:ex_ipfs_ipns, "~> 0.0.2"},
      {:ex_ipfs_pubsub, "~> 0.0.1"},
      {:nanoid, "~> 2.0"},
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
