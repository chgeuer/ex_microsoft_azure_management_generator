defmodule Generator do
  defmodule API do
    defstruct [:app_name, :package, :name, :url]
  end

  @codegen_version "2.3.1"
  @jar "swagger-codegen-cli-#{@codegen_version}.jar"
  @jar_source "http://central.maven.org/maven2/io/swagger/swagger-codegen-cli/#{@codegen_version}/swagger-codegen-cli-#{@codegen_version}.jar"
  @target "clients"

  def generate(configFile \\ "swagger.json") do
    init()

    configFile
    |> File.read!()
    |> Poison.decode!(as: [%API{}])
    |> Enum.each(&gen_api_collection/1)
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
        "-i #{api.url} -o #{@target}/#{api.package} -c #{configFileName}"

    {_stdout, 0} =
      System.cmd(
        "java",
        args |> String.split(" "),
        stderr_to_stdout: true,
        cd: Path.absname(".")
      )

    "#{@target}/#{api.package}"
    |> fix_swagger_problem()

    configFileName |> File.rm!()
  end

  defp init() do
    unless @jar |> File.exists?() do
      IO.puts("Downloading #{@jar_source}")

      {:ok, {{_, 200, 'OK'}, _headers, body}} =
        :httpc.request(:get, {String.to_charlist(@jar_source), []}, [], body_format: :binary)

      @jar |> File.write!(body)
    end
  end

  defp fix_swagger_problem(target) do
    # https://github.com/swagger-api/swagger-codegen/issues/8138
    # /usr/bin/find clients -type f -name "*.ex" -exec sed -i'' -e 's/add_param(:body, :"[^"]*", /add_param(:body, :body, /g' {} +

    fix = fn body ->
      Regex.replace(
        ~r/\|> add_param\(:body, :"[^"]+", /,
        body,
        "|> add_param(:body, :body, ",
        global: true
      )
    end

    "#{target}/**/api/*.ex"
    |> Path.wildcard()
    |> Enum.map(&%{name: &1, content: &1 |> File.read!() |> fix.()})
    |> Enum.each(&File.write!(&1.name, &1.content))
  end
end
