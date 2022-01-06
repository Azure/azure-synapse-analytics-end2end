param networkIsolationMode string
param resourceLocation string

param azureMLWorkspaceName string
param azureMLStorageAccountName string
param azureMLAppInsightsName string
param azureMLContainerRegistryName string
param keyVaultID string
param textAnalyticsAccountName string
param anomalyDetectorAccountName string

//Cognitive Services Account
resource r_textAnalytics 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: textAnalyticsAccountName
  location: resourceLocation
  kind: 'TextAnalytics'
  sku:{
    name: 'S'
  }
  identity:{
    type: 'SystemAssigned'
  }
  properties:{
    publicNetworkAccess: (networkIsolationMode == 'vNet') ? 'Disabled': 'Enabled'
    customSubDomainName: textAnalyticsAccountName
  }
}

//Anomaly Detector Account
resource r_anomalyDetector 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: anomalyDetectorAccountName
  location: resourceLocation
  kind: 'AnomalyDetector'
  sku:{
    name: 'S0'
  }
  identity:{
    type: 'SystemAssigned'
  }
  properties:{
    publicNetworkAccess: (networkIsolationMode == 'vNet') ? 'Disabled': 'Enabled'
    customSubDomainName: anomalyDetectorAccountName
  }  
}

//Azure ML Storage Account
resource r_azureMLStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name:azureMLStorageAccountName
  location:resourceLocation
  kind:'StorageV2'
  sku:{
    name:'Standard_LRS'
  }
  properties:{
    networkAcls: {
      defaultAction: (networkIsolationMode == 'vNet')? 'Deny' : 'Allow'
      bypass: 'AzureServices' 
    }
    encryption:{
      services:{
        blob:{
          enabled:true
        }
        file:{
          enabled:true
        }
      }
      keySource:'Microsoft.Storage'
    }
  }
  
}

//Azure ML Application Insights
resource r_azureMLAppInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: azureMLAppInsightsName
  location:resourceLocation
  kind:'web'
  properties:{
    Application_Type:'web'
  }
}

//Azure ML Container Registry
resource r_azureMLContainerRegistry 'Microsoft.ContainerRegistry/registries@2021-08-01-preview' = {
  name: azureMLContainerRegistryName
  location: resourceLocation
  sku: {
    name: (networkIsolationMode == 'vNet') ? 'Premium' : 'Basic' //Premium tier is required for Private Link deployment: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link#prerequisites
  }
  properties: {
    networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess:(networkIsolationMode == 'vNet') ? 'Disabled' : 'Enabled'
    networkRuleSet: (networkIsolationMode == 'vNet') ? {
      defaultAction: 'Deny'
    } : null
  }
}

//Azure Machine Learning Workspace
resource r_azureMLWorkspace 'Microsoft.MachineLearningServices/workspaces@2021-04-01' = {
  name: azureMLWorkspaceName
  location: resourceLocation
  sku:{
    name: 'Basic'
    tier: 'Basic'
  }
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    friendlyName: azureMLWorkspaceName
    keyVault: keyVaultID
    storageAccount: r_azureMLStorageAccount.id
    applicationInsights: r_azureMLAppInsights.id
    containerRegistry: r_azureMLContainerRegistry.id
    allowPublicAccessWhenBehindVnet: (networkIsolationMode == 'vNet') ? false : true
  }
}

output textAnalyticsAccountID string = r_textAnalytics.id
output textAnalyticsAccountName string = r_textAnalytics.name
output textAnalyticsEndpoint string = r_textAnalytics.properties.endpoint

output anomalyDetectorAccountID string = r_anomalyDetector.id
output anomalyDetectorAccountName string = r_anomalyDetector.name
output anomalyDetectorEndpoint string = r_anomalyDetector.properties.endpoint

output azureMLWorkspaceIdentityPrincipalID string = r_azureMLWorkspace.identity.principalId

output azureMLWorkspaceID string = r_azureMLWorkspace.id
output azureMLWorkspaceName string = r_azureMLWorkspace.name

output containerRegistryID string = r_azureMLContainerRegistry.id
output containerRegistryName string = r_azureMLContainerRegistry.name

output applicationInsightsID string = r_azureMLAppInsights.id
output applicationInsightsName string = r_azureMLAppInsights.name

output storageAccountID string = r_azureMLStorageAccount.id
output storageAccountName string = r_azureMLStorageAccount.name
