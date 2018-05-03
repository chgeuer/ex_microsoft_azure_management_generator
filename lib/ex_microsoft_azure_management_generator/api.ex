defmodule ExMicrosoftAzureManagementGenerator.API do
  defstruct [:package, :name, :url, :state, :apiVersion]

  def expand_api(api = %__MODULE__{}, baseUrl, branch),
    do: %{api | url: "#{baseUrl}/#{branch}/specification/#{api.url}"}
end
