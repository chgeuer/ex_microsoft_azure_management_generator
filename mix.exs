defmodule ExMicrosoftAzureManagementGenerator.MixProject do
  use Mix.Project

  @source_url "https://github.com/chgeuer/ex_microsoft_azure_management_generator"

  def project do
    [
      app: :ex_microsoft_azure_management_generator,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      source_url: @source_url,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets]
    ]
  end

  defp description() do
    "An SDK generator for the Microsoft Azure platform's resource management API (ARM)."
  end

  defp package() do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["Christian Geuer-Pollmann"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps do
    [
      {:poison, ">= 1.0.0"}
    ]
  end
end
