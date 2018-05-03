defmodule ExMicrosoftAzureManagementGenerator do
  alias __MODULE__.Config
  alias __MODULE__.API

  @java "java.exe"
  @jar Application.get_env(:ex_microsoft_azure_management_generator, :jar_version)
  @jar_source Application.get_env(:ex_microsoft_azure_management_generator, :jar_source)
              |> String.to_charlist()

  @baseUrl "https://raw.githubusercontent.com/Azure/azure-rest-api-specs"
  @branch "master"
  @url_pref @baseUrl <> "/" <> @branch <> "/specification/"

  def init() do
    unless @jar |> File.exists?() do
      Application.ensure_all_started(:inets)

      {:ok, resp} = :httpc.request(:get, {@jar_source, []}, [], body_format: :binary)
      {{_, 200, 'OK'}, _headers, body} = resp

      @jar |> File.write!(body)
    end
  end

  def generate([]), do: :ok

  def generate([api = %API{} | tail]) do
    generatorConfig =
      %{packageName: "azure", invokerPackage: "#{api.name}"}
      |> Poison.encode!(pretty: true)

    IO.puts("Writing package=#{api.package} name=#{api.name}")

    File.write!("#{api.name}.json", generatorConfig)

    {_stdout, 0} =
      System.cmd(
        @java,
        [
          "-jar",
          "#{@jar}",
          "generate",
          "-l",
          "elixir",
          "-i",
          "#{api.url}",
          "-o",
          "clients/#{api.package}",
          "-c",
          Path.absname("#{api.name}.json")
        ],
        stderr_to_stdout: true,
        cd: Path.absname(".")
      )

    File.rm!("#{api.name}.json")

    generate(tail)
  end

  defp parse_config_file(filename) do
    filename
    |> Path.absname()
    |> File.read!()
    |> Config.parse()
  end

  def generate_from_json() do
    "swagger.json"
    |> parse_config_file()
    |> generate()
  end

  defp tweak_name(name) do
    name
    |> String.replace("Microsoft.", "Microsoft.Azure.Management.")
    |> String.replace("DBforMySQL", "DbForMysql")
    |> String.replace("DBforPostgreSQL", "DbForPostgresql")
    |> String.replace("PowerBIdedicated", "PowerBiDedicated")
  end

  defp to_api(l = [pref, "resource-management", api_version, file]),
    do: %API{
      package: "Microsoft.Azure.Management",
      url: @url_pref <> Enum.join(l, "/"),
      apiVersion: api_version
    }

  defp to_api(l = [pref, "resource-manager", name, state, api_version, file]),
    do: %API{
      package: "Microsoft.Azure.Management",
      name: name |> tweak_name(),
      url: @url_pref <> Enum.join(l, "/"),
      state: state,
      apiVersion: api_version
    }

  defp to_api(l = [pref, "resource-manager", name, state, api_version, area, file]),
    do: %API{
      package: "Microsoft.Azure.Management",
      name: name |> tweak_name(),
      url: @url_pref <> Enum.join(l, "/"),
      state: state,
      apiVersion: api_version
    }

  defp to_api(l = ["azsadmin", "resource-manager", area, name, state, api_version, file]), do: nil
  defp to_api(l = [pref, "control-plane", name, state, api_version, file]), do: nil
  defp to_api(l = [pref, "data-plane", name, area, state, api_version, file]), do: nil
  defp to_api(l = [pref, "data-plane", name, state, api_version, file]), do: nil
  defp to_api(l = [pref, "data-plane", name, api_version, file]), do: nil
  defp to_api(l = [pref, "data-plane", name, file]), do: nil

  defp parse_url(line) do
    line
    |> String.trim()
    |> String.split("/")
    |> to_api()
  end

  def generate_from_text_file(text_file_name) do
    text_file_name
    |> File.stream!([:read, :utf8], :line)
    |> Stream.map(&parse_url/1)
    |> Stream.filter(&(&1 != nil))
    |> Enum.map(& &1)
    |> generate()
  end

  def generate_from_text_file(), do: "swagger.txt" |> Path.absname() |> generate_from_text_file()
end
