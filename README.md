During our experience with Java Azure Function, we spot a weird behavior with the Azure Pipeline for Java Azure Function.

Firstly we had the Function App created as ***Y1 / Standard***, like this :

```
resource dutyofcareparseFunctionPlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  ...
  sku: {
    name: 'Y1'
    tier: 'Standard'
  }
  ...
}
```

Deploying a Java Azure Function with VSCode --> works

Deploying a Java Azure Function with Azure Pipeline (described in azure-pipeline.yml) --> does not work

After sometime, we changed the Function App to ***B1 / Basic*** and the same Azure Pipeline started working.

```
resource dutyofcareparseFunctionPlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  ...
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  ...
}
```

***

> We are running those PS scripts inside an Azure Pipeline to automate. These extracts are to try to ease reproduction on Microsoft side.

## How to reproduce the issue:

**Step 1** - Install the Resource Group
```
.\deploy\resource-group-deployment.ps1 'YOUR-RESOURCE-GROUP' 'YOUR-REGION' $env:SP_ID $env:SP_SECRET $env:TENANT_ID 'YOUR-SUBSCRIPTION'
```

**Step 2** - Install the Resources
```
.\deploy\ingestion-resources-deployment.ps1 'YOUR-RESOURCE-GROUP' $env:SP_ID $env:SP_SECRET $env:TENANT_ID 'YOUR-SUBSCRIPTION' .\deploy\parameters\ingestion-resources-params.json
```

**Step 3** - Change values in the Pipeline
> ***REMARK***
>
> This azure-pipeline.yml is not to run for this repository. Copy and paste it and use as reference for a Maven Azure Function repository
```
You need to change the following variables:
- serviceConnectionToAzure : the ARM service you create for your subscription
- functionAppName : no need to change if you didn't touch the file deploy/parameters/ingestion-resources-params.json
- azureFunctionName : the Azure Function Name you created with Maven Azure Function archetype
```

Please see [this video](https://github.com/dskajita/msft_function_pipeline_failure/issues/1) describing the issue in this github in the issues