defmodule Generator do
  alias __MODULE__.Config
  alias __MODULE__.API

  @java "java"
  @jar Application.get_env(:ex_microsoft_azure_management_generator, :jar_version)
  @jar_source Application.get_env(:ex_microsoft_azure_management_generator, :jar_source) |> String.to_charlist()

  # @baseUrl "https://raw.githubusercontent.com/Azure/azure-rest-api-specs"
  # @branch "master"
  # @url_pref @baseUrl <> "/" <> @branch <> "/specification/"

  defp init() do
    unless @jar |> File.exists?() do
      Application.ensure_all_started(:inets)

      {:ok, resp} = :httpc.request(:get, {@jar_source, []}, [], body_format: :binary)
      {{_, 200, 'OK'}, _headers, body} = resp

      @jar |> File.write!(body)
    end
  end

  defp generate(url, app_name, package, name) do
    init()

    IO.puts("app_name=#{app_name} package=#{package} name=#{name} url=#{url}")

    generatorConfig =
      %{packageName: app_name, invokerPackage: "#{name}"}
      |> Poison.encode!(pretty: true)

    configFileName = "#{name}.json"
    configFileName |> File.write!(generatorConfig)

    args = "-jar #{@jar} generate -l elixir " <>
      "-i #{url} -o clients/#{package} -c #{configFileName}"

    IO.puts("Running #{@java} #{args}")

    {_stdout, 0} = System.cmd(@java,
        args |> String.split(" "),
        stderr_to_stdout: true,
        cd: Path.absname(".")
      )

    configFileName |> File.rm!()
  end

  defp gen_api_collection(%API{app_name: app_name, package: package, name: name, url: urls}), do:
    urls |> Enum.each(&(&1 |> generate(app_name, package, name)))

  def generate() do
    "swagger.json"
    |> File.read!()
    |> Config.parse()
    |> Enum.each(&gen_api_collection/1)

    # Fixing body handling (https://github.com/swagger-api/swagger-codegen/issues/8138)
    System.cmd("sh", ["fix_body.sh"], stderr_to_stdout: true, cd: Path.absname("clients"))
  end
end
