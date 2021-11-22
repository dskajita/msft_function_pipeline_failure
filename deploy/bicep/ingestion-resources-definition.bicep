// Ingestion: 

// 1 Function App: studio-dutyofcare-parse (Function name:ParseDutyOfCare)
param dutyofcareparseFunctionAppName string
param dutyofcareparseFunctionPlanName string

// storage accounts must be between 3 and 24 characters in length and use numbers and lower-case letters only
var dutyofcareparseNameWithoutUnderscore = replace(dutyofcareparseFunctionAppName, '-', '')
var dutyofcareparseStorageAccountName = toLower(dutyofcareparseNameWithoutUnderscore)

// 1 Event Hub:studio-dutyofcare-parse
var dutyofcareparseEventHubNamespaceName = dutyofcareparseFunctionAppName
var dutyofcareparseEhAuthRuleResourceId = resourceId('Microsoft.EventHub/namespaces/authorizationRules', dutyofcareparseEventHubNamespaceName, 'RootManageSharedAccessKey')

param sampleTags object = {
  sample: 'am-studio-dutyofcare-ingestion'
  owner: 'Amadeus'
}

// Event Hub:studio-dutyofcare-parse
resource dutyofcareparseEventHubNamespace 'Microsoft.EventHub/namespaces@2017-04-01' = {
  name: dutyofcareparseEventHubNamespaceName
  location: resourceGroup().location
  tags: sampleTags
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: true
    maximumThroughputUnits: 20
    kafkaEnabled: false
  }

  resource sampleEventHub 'eventhubs' = {
    name: 'sample'
    properties: {
      messageRetentionInDays: 1
      partitionCount: 32
    }

    resource net3ConsumerGroup 'consumergroups' = {
      name: 'net3'
    }

  }
}

// Function App: studio-dutyofcare-parse (Function name:ParseDutyOfCare)
resource dutyofcareparseStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: dutyofcareparseStorageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  tags: sampleTags

  resource dutyofcareparseStorageBlobServices 'blobServices' = {
    name: 'default'
  }
}

var dutyofcareparseStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${dutyofcareparseStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(dutyofcareparseStorageAccount.id, dutyofcareparseStorageAccount.apiVersion).keys[0].value}'

resource dutyofcareparseFunctionPlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: dutyofcareparseFunctionPlanName
  location: resourceGroup().location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: 'Y1'
    tier: 'Standard'
  }
  tags: sampleTags
}

resource dutyofcareparseInsightsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  location: resourceGroup().location
  name: dutyofcareparseFunctionAppName
  tags: sampleTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource dutyofcareparseAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: dutyofcareparseFunctionAppName
  location: resourceGroup().location
  kind: 'web'
  tags: sampleTags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: dutyofcareparseInsightsWorkspace.id
    IngestionMode: 'LogAnalytics'
  }
}

resource dutyofcareparseFunctionApp 'Microsoft.Web/sites@2021-01-15' = {
  name: dutyofcareparseFunctionAppName
  location: resourceGroup().location
  kind: 'functionapp'
  tags: sampleTags
  properties: {
    serverFarmId: dutyofcareparseFunctionPlan.id
    siteConfig: {
      linuxFxVersion: 'Java|8'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: dutyofcareparseStorageConnectionString
        }
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': dutyofcareparseAppInsights.properties.InstrumentationKey
        }
        {
          'name': 'EventHubConnection'
          'value': listkeys(dutyofcareparseEhAuthRuleResourceId, dutyofcareparseEventHubNamespace::sampleEventHub.apiVersion).primaryConnectionString
        }
        {
          'name': 'EventHubName'
          'value': dutyofcareparseEventHubNamespace::sampleEventHub.name
        }
        {

          'name': 'EventHubPartitions'
          'value': '32'
        }
        {
          'name': 'FUNCTIONS_WORKER_RUNTIME'
          'value': 'java'
        }
        {
          'name': 'FUNCTIONS_EXTENSION_VERSION'
          'value': '~3'
        }
      ]
    }
  }
}

output dutyofcareparseFunctionAppName string = dutyofcareparseFunctionApp.name
output dutyofcareparseEventHubName string = 'https://${dutyofcareparseFunctionApp.name}.azurewebsites.net/api/PostToEventHub?code=${listkeys('${dutyofcareparseFunctionApp.id}/host/default/', dutyofcareparseFunctionApp.apiVersion).functionKeys.default}'
output dutyofcareparseStorageAccountName string = dutyofcareparseStorageAccount.name
