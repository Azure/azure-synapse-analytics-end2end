param deploymentMode string
param resourceLocation string

param ctrlDeployPrivateDNSZones bool 
param ctrlSynapseDeploySparkPool bool
param azureMLWorkspaceName string
param azureMLStorageAccountName string
param azureMLAppInsightsName string
param azureMLContainerRegistryName string
param keyVaultName string
param synapseWorkspaceName string
param synapseWorkspaceID string
param synapseSparkPoolID string
param textAnalyticsAccountName string
param anomalyDetectorAccountName string
param vNetSubnetID string

var storageEnvironmentDNS = environment().suffixes.storage

resource r_privateDNSZoneStorageBlob 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.blob.${storageEnvironmentDNS}'
} 

resource r_privateDNSZoneStorageFile 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.file.${storageEnvironmentDNS}'
} 

//Private DNS Zone for Azure Container Registry
resource r_privateDNSZoneACR 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.azurecr.io'
} 

//Azure Machine Learning Workspace DNS Zone: privatelink.azurecr.io
//Required by Azure ML
resource r_privateDNSZoneAzureMLAPI 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.api.azureml.ms'
}
//Azure Machine Learning Workspace DNS Zone: privatelink.notebooks.azure.net
//Required by Azure ML
resource r_privateDNSZoneAzureMLNotebooks 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.notebooks.azure.net'
}

//Cognitive Services Account
resource r_textAnalytics 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: textAnalyticsAccountName
  location: resourceLocation
  kind: 'TextAnalytics'
  sku:{
    name: 'F0'
  }
}

//Anomaly Detector Account
resource r_anomalyDetector 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: anomalyDetectorAccountName
  location: resourceLocation
  kind: 'AnomalyDetector'
  sku:{
    name: 'F0'
  }
}

//Reference existing Key Vault created by CoreServicesDeploy.bicep
resource r_keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName

  resource r_textAnalyticsAccountKey 'secrets' = {
    name:'${r_textAnalytics.name}-Key'
    properties:{
      value: listKeys(r_textAnalytics.id,r_textAnalytics.apiVersion).key1
    }
  }

  resource r_anomalyDetectorAccountKey 'secrets' = {
    name:'${r_anomalyDetector.name}-Key'
    properties:{
      value: listKeys(r_anomalyDetector.id,r_anomalyDetector.apiVersion).key1
    }
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

//Private Link for Storage Account Blob
module m_dataLakeStorageAccountBlobPrivateLink './PrivateEndpoint.bicep' = if(deploymentMode == 'vNet'){
  name: '${r_azureMLStorageAccount.name}-blob'
  params: {
    groupID: 'blob'
    privateEndpoitName: '${r_azureMLStorageAccount.name}-blob'
    privateLinkServiceId: r_azureMLStorageAccount.id
    resourceLocation: resourceLocation
    subnetID: vNetSubnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
    privateDNSZoneConfigs:[
      {
        name:'privatelink-blob-core-windows-net'
        properties:{
          privateDnsZoneId: r_privateDNSZoneStorageBlob.id
        }
      }
    ]
  }
}

//Private Link for Storage Account File
module m_dataLakeStorageAccountFilePrivateLink './PrivateEndpoint.bicep' = if(deploymentMode == 'vNet'){
  name: '${r_azureMLStorageAccount.name}-file'
  params: {
    groupID: 'file'
    privateEndpoitName: '${r_azureMLStorageAccount.name}-file'
    privateLinkServiceId: r_azureMLStorageAccount.id
    resourceLocation: resourceLocation
    subnetID: vNetSubnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
    privateDNSZoneConfigs: [
      {
        name:'privatelink-file-core-windows-net'
        properties:{
          privateDnsZoneId: r_privateDNSZoneStorageFile.id
        }
      }
    ]
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
resource r_azureMLContainerRegistry 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: azureMLContainerRegistryName
  location: resourceLocation
  sku: {
    name: (deploymentMode == 'vNet') ? 'Premium' : 'Basic' //Premium tier is required for Private Link deployment: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link#prerequisites
  }
  properties: {
    
  }
}

//Private Link for Azure Container Registry
module m_azureMLContainerRegistryPrivateLInk './PrivateEndpoint.bicep' = if(deploymentMode == 'vNet'){
  name: '${r_azureMLContainerRegistry.name}-registry'
  params: {
    groupID: 'registry'
    privateEndpoitName: '${r_azureMLContainerRegistry.name}-registry'
    privateLinkServiceId: r_azureMLContainerRegistry.id
    resourceLocation: resourceLocation
    subnetID: vNetSubnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
    privateDNSZoneConfigs: [
      {
        name:'privatelink-azurecr-io'
        properties:{
          privateDnsZoneId: r_privateDNSZoneACR.id
        }
      }
    ]
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
    keyVault: r_keyVault.id
    storageAccount: r_azureMLStorageAccount.id
    applicationInsights: r_azureMLAppInsights.id
    containerRegistry: r_azureMLContainerRegistry.id
  }

  resource r_azureMLSynapseSparkCompute 'computes' = if(ctrlSynapseDeploySparkPool == true) {
    name: 'SynapseSparkPool'
    location: resourceLocation
    properties:{
      computeType:'SynapseSpark'
      resourceId: ctrlSynapseDeploySparkPool ? synapseSparkPoolID : ''
    }
  }
}

resource r_azureMLSynapseLinkedService 'Microsoft.MachineLearningServices/workspaces/linkedServices@2020-09-01-preview' = {
  name: synapseWorkspaceName
  location: resourceLocation
  parent: r_azureMLWorkspace
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    linkedServiceResourceId: synapseWorkspaceID
  }
}

module m_azureMLWorkspacePrivateLink 'PrivateEndpoint.bicep' = if(deploymentMode == 'vNet') {
  name: 'AzureMLWorkspacePrivateLink'
  params: {
    groupID: 'amlworkspace'
    privateDNSZoneConfigs: [
      {
        name:'privatelink-api-azureml-ms'
        properties:{
          privateDnsZoneId: r_privateDNSZoneAzureMLAPI.id
        }
      }
      {
        name:'privatelink-notebooks-azure-net'
        properties:{
          privateDnsZoneId: r_privateDNSZoneAzureMLNotebooks.id
        }
      }
    ]
    privateEndpoitName: '${azureMLWorkspaceName}-amlworkspace'
    privateLinkServiceId: r_azureMLWorkspace.id
    resourceLocation: resourceLocation
    subnetID: vNetSubnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
  }
}

output textAnalyticsAccountID string = r_textAnalytics.id
output textAnalyticsEndpoint string = r_textAnalytics.properties.endpoint
output anomalyDetectorAccountID string = r_anomalyDetector.id
output anomalyDetectorEndpoint string = r_anomalyDetector.properties.endpoint
output azureMLWorkspaceIdentityPrincipalID string = r_azureMLWorkspace.identity.principalId
output azureMLSynapseLinkedServicePrincipalID string = r_azureMLSynapseLinkedService.identity.principalId
output azureMLWorkspaceID string = r_azureMLWorkspace.id
