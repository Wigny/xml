defmodule XML.MixProject do
  use Mix.Project

  def project do
    [
      app: :xml,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [applications: [:xmerl]]
  end

  defp deps do
    [
      {:git_snapshot, "~> 0.1"}
    ]
  end
end
