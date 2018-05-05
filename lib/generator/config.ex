defmodule Generator.Config do
  alias __MODULE__
  alias Generator.API

  defstruct [:baseUrl, :branch, :apis]

  def parse(json_string) do
    %__MODULE__{
      baseUrl: baseUrl,
      branch: branch,
      apis: apis
    } = json_string |> Poison.decode!(as: %Config{apis: [%API{}]})

    apis
    |> Enum.map(&(&1 |> API.expand_api(baseUrl, branch)))
  end
end
