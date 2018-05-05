defmodule Generator do
  defmodule API do
    defstruct [:app_name, :package, :name, :url]
  end

  @java "java"
  @codegen_version "2.3.1"
  @jar "swagger-codegen-cli-#{@codegen_version}.jar"
  @jar_source "http://central.maven.org/maven2/io/swagger/swagger-codegen-cli/#{@codegen_version}/swagger-codegen-cli-#{@codegen_version}.jar"
  @apiConfigFile "swagger.json"

  def generate() do
    init()

    @apiConfigFile
    |> File.read!()
    |> Poison.decode!(as: [%API{}])
    |> Enum.each(&gen_api_collection/1)

    # https://github.com/swagger-api/swagger-codegen/issues/8138
    System.cmd("sh", ["fix_body.sh"], stderr_to_stdout: true, cd: Path.absname("clients"))
  end

  defp init() do
    unless @jar |> File.exists?() do
      Application.ensure_all_started(:inets)

      {:ok, resp} = :httpc.request(:get, {@jar_source, []}, [], body_format: :binary)
      {{_, 200, 'OK'}, _headers, body} = resp

      @jar |> File.write!(body)
    end
  end

  defp gen_api_collection(api = %API{}) do
    api.url
    |> Enum.each(
      &(Map.put(api, :url, &1)
        |> generate())
    )
  end

  defp write_local_config_file(configFileName, app_name, name) do
    generatorConfig =
      %{packageName: app_name, invokerPackage: "#{name}"}
      |> Poison.encode!(pretty: true)

    configFileName |> File.write!(generatorConfig)
  end

  defp generate(api = %API{}) do
    api.url
    |> String.replace_leading("https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/specification", "")
    |> IO.puts()

    configFileName = "#{api.name}.json"
    configFileName |> write_local_config_file(api.app_name, api.name)
    args = "-jar #{@jar} generate -l elixir -i #{api.url} -o clients/#{api.package} -c #{configFileName}"

    {_stdout, 0} =
      System.cmd(
        @java,
        args |> String.split(" "),
        stderr_to_stdout: true,
        cd: Path.absname(".")
      )

    configFileName |> File.rm!()
  end
end
