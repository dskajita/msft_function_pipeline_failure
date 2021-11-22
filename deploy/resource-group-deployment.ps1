function assignContributorRoleToSP {
    param (
        [string]$sp, [string]$rg
    )
    az role assignment create --assignee $sp --role "Contributor" --resource-group $rg
}

$resourceGroupName = $args[0]
$location = $args[1]
$spId = $args[2]
$spSecret = $args[3]
$tenantId = $args[4]
$subscription = $args[5]

Write-Host "There are a total of $($args.Count) arguments"
for ( $i = 0; $i -lt $args.count; ++$i ) {
    write-host "Argument  $i is $($args[$i])"
}

az login --service-principal --username $spId --password $spSecret --tenant $tenantId
az account set --subscription $subscription

$resourceGroupExists = az resource list --resource-group $resourceGroupName 2>&1
#Check if there is an error in the command, if there is, we exit with an error
if($? -eq $false) {
    Write-Host "There is an error returned by previous command. Error is : $resourceGroupExists"
    if ($resourceGroupExists -match 'ERROR: \(ResourceGroupNotFound\)') {
        Write-Host "There is no Resource Group with name $($resourceGroupName) in $($subscription). We are going to create the RG"
        az group create --name $resourceGroupName --location $location
        assignContributorRoleToSP -sp $spId -rg $resourceGroupName
    } else {
        Write-Host "We did not match the expected error, so we throw"
        throw $err
    }
} else {
    Write-Host "Resource Group with name $($resourceGroupName) in $($subscription) already exists. Skipping creation of the RG"

    # We need to check if the RG already have the SP able to create / deploy things
    $spHasRights = az role assignment list --assignee $spId --resource-group $resourceGroupName --output json | ConvertFrom-Json
    # Write-Host "spHasRights $($spHasRights) has $($spHasRights.count)"
    if ($($spHasRights.count) -eq 0) {
        Write-Host "The $($resourceGroupName) does not contain a role assigned for SP. Lets create role assignment."
        assignContributorRoleToSP -sp $spId -rg $resourceGroupName
    } else {
        Write-Host "The $($resourceGroupName) already has the correct role assigned. Skipping role assignment"
    }
}

exit(0)