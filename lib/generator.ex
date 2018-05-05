defmodule Generator do
  defmodule API do
    defstruct [:app_name, :package, :name, :url]
  end

  @codegen_version "2.3.1"
  @jar "swagger-codegen-cli-#{@codegen_version}.jar"
  @jar_source "http://central.maven.org/maven2/io/swagger/swagger-codegen-cli/#{@codegen_version}/swagger-codegen-cli-#{@codegen_version}.jar"

  def generate(configFile \\ "swagger.json") do
    init()

    configFile
    |> File.read!()
    |> Poison.decode!(as: [%API{}])
    |> Enum.each(&gen_api_collection/1)

    fix_swagger_problem()
  end

  defp gen_api_collection(api = %API{}) do
    api.url
    |> Enum.each(
      &(Map.put(api, :url, &1)
        |> generate_impl())
    )
  end

  defp write_local_config_file(configFileName, app_name, name) do
    generatorConfig =
      %{packageName: app_name, invokerPackage: "#{name}"}
      |> Poison.encode!(pretty: true)

    configFileName |> File.write!(generatorConfig)
  end

  defp generate_impl(api = %API{}) do
    api.url
    |> String.replace_leading(
      "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/specification/",
      ""
    )
    |> IO.puts()

    configFileName = "#{api.name}.json"
    configFileName |> write_local_config_file(api.app_name, api.name)

    args =
      "-jar #{@jar} generate -l elixir " <>
        "-i #{api.url} -o clients/#{api.package} -c #{configFileName}"

    {_stdout, 0} =
      System.cmd(
        "java",
        args |> String.split(" "),
        stderr_to_stdout: true,
        cd: Path.absname(".")
      )

    configFileName |> File.rm!()
  end

  defp fix_swagger_problem() do
    # https://github.com/swagger-api/swagger-codegen/issues/8138

    {_stdout, 0} = System.cmd("/bin/sh", ["fix_body.sh"], stderr_to_stdout: true)
  end

  defp init() do
    unless @jar |> File.exists?() do
      IO.puts("Downloading #{@jar_source}")

      {:ok, {{_, 200, 'OK'}, _headers, body}} =
        :httpc.request(:get, {String.to_charlist(@jar_source), []}, [], body_format: :binary)

      @jar |> File.write!(body)
    end
  end
end
