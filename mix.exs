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
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:progress_bar, "~> 3.0"}
    ]
  end

  defp escript do
    [main_module: NervesBurner.CLI]
  end
end
