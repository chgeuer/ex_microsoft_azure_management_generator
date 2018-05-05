defmodule ExMicrosoftAzureManagementGenerator.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_microsoft_azure_management_generator,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:poison, ">= 1.0.0"}
    ]
  end
end
