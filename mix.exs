defmodule NervesBurner.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_burner,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl, :crypto]
    ]
  end

  defp deps do
    [
      # Jason is built into newer Elixir versions via the JSON module
      # For now, we'll use a simple JSON parser or fallback
    ]
  end

  defp escript do
    [main_module: NervesBurner.CLI]
  end
end
