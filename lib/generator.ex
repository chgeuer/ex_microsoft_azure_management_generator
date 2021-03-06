defmodule Generator do
  defmodule API do
    defstruct [:app_name, :package, :name, :url]
  end

  @moduledoc """
  Generates Elixir SDKs from Microsoft Azure Swagger specifications.
  """

  # @codegen_version "2.3.1"
  @codegen_version "custom"
  @jar "swagger-codegen-cli-#{@codegen_version}.jar"
  @jar_source "http://central.maven.org/maven2/io/swagger/swagger-codegen-cli/#{@codegen_version}/swagger-codegen-cli-#{
                @codegen_version
              }.jar"
  @target "clients"

  @doc """
  Reads `configFile` JSON and creates the client SDK.

  Returns `:ok`.

  ## Examples

      iex> Generator.generate("swagger.json")
      :ok
  """
  def generate(configFile \\ "swagger.json") do
    init()

    configFile
    |> File.read!()
    |> Poison.decode!(as: [%API{}])
    |> Enum.each(&gen_api_collection/1)

    :ok
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
    |> IO.inspect()
    |> String.replace_leading(
      # "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/specification/",
      "https://raw.githubusercontent.com/chgeuer/azure-rest-api-specs/master/specification/",
      ""
    )
    |> IO.puts()

    configFileName = "#{api.name}.json"
    configFileName |> write_local_config_file(api.app_name, api.name)

    # # "C:\Program Files\Java\jre1.8.0_171\bin\keytool.exe" -import -file C:\Users\chgeuer\Desktop\FiddlerRoot.cer -keystore FiddlerKeystore -alias Fiddler
    # "-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8888 " <>
    # "-Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=8888 " <>
    # "-Djavax.net.ssl.trustStore=FiddlerKeystore " <>
    # "-Djavax.net.ssl.trustStorePassword=test123 " <>
    args =
      "-jar #{@jar} generate " <>
        "-l elixir " <> "-i #{api.url} -o #{@target}/#{api.package} -c #{configFileName}"

    IO.puts(args)

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
    fix_files("#{target}/**/api/*.ex", &fix_api/1)
    fix_files("#{target}/**/model/*.ex", &fix_model/1)
  end

  defp fix_files(wildcard, fixes) do
    wildcard
    |> Path.wildcard()
    |> Enum.each(fn filename ->
      content =
        filename
        |> File.read!()
        |> fixes.()

      File.write!(filename, content)
    end)
  end

  defp regex_pipe(body, regex, replacement, opts),
    do: Regex.replace(regex, body, replacement, opts)

  # https://github.com/swagger-api/swagger-codegen/issues/8138
  # /usr/bin/find clients -type f -name "*.ex" -exec sed -i'' -e 's/add_param(:body, :"[^"]*", /add_param(:body, :body, /g' {} +
  defp fix_api(x),
    do:
      x
      |> regex_pipe(
        ~r/\|> add_param\(:body, :"[^"]+", /,
        ~s/|> add_param(:body, :body, /,
        global: true
      )

  defp fix_model(x),
    do:
      x
      |> regex_pipe(
        # |> deserialize(:"parameters", :struct, Microsoft.Azure.Management.Resources.Model.Object, options)
        ~r/(\|> deserialize\(:"[^"]+", :struct, .+?\.Model.Object, options)/,
        ~s/#\\1/,
        global: true
      )
end
