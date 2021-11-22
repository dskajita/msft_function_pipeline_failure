$resourceGroupName = $args[0]
$spId = $args[1]
$spSecret = $args[2]
$tenantId = $args[3]
$subscription = $args[4]
$paramsfileName = $args[5]

$bicepfileName =".\deploy\bicep\ingestion-resources-definition.bicep"

Write-Host "Test2 Script"

az login --service-principal --username $spId --password $spSecret --tenant $tenantId
az account set --subscription $subscription
az deployment group create --resource-group $resourceGroupName --template-file $bicepfileName --parameters @$paramsFileName