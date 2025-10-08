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
      {:req, github: "wojtekmach/req", tag: "v0.4.14"},
      {:finch, github: "sneako/finch", tag: "v0.18.0", override: true},
      {:mime, github: "elixir-plug/mime", tag: "v2.0.6", override: true},
      {:jason, github: "michalmuskala/jason", tag: "v1.4.4", override: true},
      {:nimble_ownership, github: "dashbitco/nimble_ownership", tag: "v0.3.0", override: true},
      {:nimble_pool, github: "dashbitco/nimble_pool", tag: "v1.1.0", override: true},
      {:nimble_options, github: "dashbitco/nimble_options", tag: "v1.1.1", override: true},
      {:mint, github: "elixir-mint/mint", tag: "v1.6.2", override: true},
      {:hpax, github: "elixir-mint/hpax", tag: "v1.0.0", override: true},
      {:castore, github: "elixir-mint/castore", tag: "v1.0.9", override: true},
      {:telemetry, github: "beam-telemetry/telemetry", tag: "v1.3.0", override: true}
    ]
  end

  defp escript do
    [main_module: NervesBurner.CLI]
  end
end
