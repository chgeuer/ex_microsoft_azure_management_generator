defmodule Generator.Config do
  alias Generator.API

  def parse(json_string) do
    json_string
    |> Poison.decode!(as: [%API{}])
  end
end
