# ExMicrosoftAzureManagementGenerator

Generates Elixir SDKs from Microsoft Azure Swagger specifications. 

## Dependencies

- Java

## How to run

```bash
mix deps.get
./generate.sh
```

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
