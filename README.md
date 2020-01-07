# ExMicrosoftAzureManagementGenerator

Generates Elixir SDKs from Microsoft Azure Swagger specifications. 

## Download

Available on [hex.pm](https://hex.pm/packages/ex_microsoft_azure_management_generator) and [GitHub](https://github.com/chgeuer/ex_microsoft_azure_management_generator).

## Support

This is *not* an official SDK from the Microsoft Azure team, but a generator by an Elixir noob. 

## Maturity

The code generated by this tool is not yet 100% checked. I have been able to `GET` information from the Azure Resource Manager API, as well as making deployments (`PUT`). For examples, please see the [chgeuer/ex_microsoft_azure_management_samples](https://github.com/chgeuer/ex_microsoft_azure_management_samples/blob/master/lib/sample.ex) repository. 

## Dependencies

- Java must be installed

## How to run

Do a `mix deps.get`  (obviously) and simply call `./generate.sh` on Linux or `.\generate.cmd` on Windows. This will read the `swagger.json` file, pull the mentioned Swagger 2.0 definitions from the Azure Swagger specifications repo, and build the clients. Check the [config section](#configuration) for details. 

## Configuration

The example configuration in `swagger.json` below generates two SDKs, one for the Azure Compute provider, and one for the PostgreSQL managed database. 

The compute SDK joins multiple Swagger definitions (`skus`, `compute`, `runCommands` and `disk`) in a single Elixir SDK. 

```json
[
    { 
        "app_name": "ex_microsoft_azure_management_compute",
        "package": "Microsoft.Azure.Management.Compute", 
        "name": "Microsoft.Azure.Management.Compute", 
        "url": [
            "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/specification/compute/resource-manager/Microsoft.Compute/stable/2017-09-01/skus.json",
            "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/specification/compute/resource-manager/Microsoft.Compute/stable/2017-12-01/compute.json",
            "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/specification/compute/resource-manager/Microsoft.Compute/stable/2017-12-01/runCommands.json",
            "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/specification/compute/resource-manager/Microsoft.Compute/stable/2018-04-01/disk.json"
         ]
    },
    { 
        "app_name": "ex_microsoft_azure_management_postgresql",
        "package": "Microsoft.Azure.Management.Database.PostgreSql", 
        "name": "Microsoft.Azure.Management.Database.PostgreSql", 
        "url": [ 
            "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/specification/postgresql/resource-manager/Microsoft.DBforPostgreSQL/stable/2017-12-01/postgresql.json"
         ]
    },
    ...
]
```

# notes

```cmd
REM https://openapi-generator.tech/docs/customization

java -jar C:\github\openapitools\openapi-generator\modules\openapi-generator-cli\target\openapi-generator-cli.jar help generate
```