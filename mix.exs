defmodule MyspaceObject.MixProject do
  @moduledoc """
  Mix project for MyspaceObject
  """
  use Mix.Project

  def project do
    [
      app: :myspace_object,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:myspace_ipfs, git: "https://github.com/bahner/myspace-ipfs", ref: "21d300d"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:excoveralls, "~> 0.15", only: :test, runtime: false}
    ]
  end
end
