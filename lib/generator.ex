defmodule Generator do
  alias __MODULE__.Config
  alias __MODULE__.API

  @java "java"
  @jar Application.get_env(:ex_microsoft_azure_management_generator, :jar_version)
  @jar_source Application.get_env(:ex_microsoft_azure_management_generator, :jar_source) |> String.to_charlist()

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

  defp generate(api = %API{}) do
    init()

    IO.puts("Writing package=#{api.package} name=#{api.name}")

    generatorConfig =
      %{packageName: "microsoft_azure_management", invokerPackage: "#{api.name}"}
      |> Poison.encode!(pretty: true)

    configFileName = "#{api.name}.json"
    configFileName |> File.write!(generatorConfig)

    args = "-jar #{@jar} generate -l elixir " <>
      "-i #{api.url} -o clients/#{api.package} -c #{configFileName}"

    IO.puts("Running #{@java} #{args}")

    {_stdout, 0} = System.cmd(@java,
        args |> String.split(" "),
        stderr_to_stdout: true,
        cd: Path.absname(".")
      )

    configFileName |> File.rm!()
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
    |> Enum.each(&generate/1)
  end

  defp tweak_name(name) do
    name
    |> String.replace("Microsoft.", "Microsoft.Azure.Management.")
    |> String.replace("DBforMySQL", "DbForMysql")
    |> String.replace("DBforPostgreSQL", "DbForPostgresql")
    |> String.replace("PowerBIdedicated", "PowerBiDedicated")
  end

  defp to_api(l = [_pref, "resource-management", api_version, _file]), do: %API{ package: "Microsoft.Azure.Management", url: @url_pref <> Enum.join(l, "/"), apiVersion: api_version}
  defp to_api(l = [_pref, "resource-manager", name, state, api_version, _file]), do: %API{ package: "Microsoft.Azure.Management", name: name |> tweak_name(), url: @url_pref <> Enum.join(l, "/"), state: state, apiVersion: api_version }
  defp to_api(l = [_pref, "resource-manager", name, state, api_version, _area, _file]), do: %API{ package: "Microsoft.Azure.Management", name: name |> tweak_name(), url: @url_pref <> Enum.join(l, "/"), state: state, apiVersion: api_version }
  defp to_api(["azsadmin", "resource-manager", _area, _name, _state, _api_version, _file]), do: nil
  defp to_api([_pref, "control-plane", _name, _state, _api_version, _file]), do: nil
  defp to_api([_pref, "data-plane", _name, _area, _state, _api_version, _file]), do: nil
  defp to_api([_pref, "data-plane", _name, _state, _api_version, _file]), do: nil
  defp to_api([_pref, "data-plane", _name, _api_version, _file]), do: nil
  defp to_api([_pref, "data-plane", _name, _file]), do: nil

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
    # |> Enum.map(& &1)
    |> Enum.each(&generate/1)

    IO.puts("Fixing body handling (https://github.com/swagger-api/swagger-codegen/issues/8138)")
    System.cmd("sh", ["fix_body.sh"], stderr_to_stdout: true, cd: Path.absname("clients"))
  end

  def generate_from_text_file(), do: "swagger.txt" |> Path.absname() |> generate_from_text_file()
end
