param ctrlDeployPurview bool
param ctrlDeployStreaming bool
param ctrlDeployAI bool 
param ctrlSynapseDeploySparkPool bool
param ctrlStreamIngestionService string

param resourceLocation string

param uamiPrincipalID string

param purviewIdentityPrincipalID string
param synapseWorkspaceIdentityPrincipalID string
param keyVaultName string
param azureMLWorkspaceName string 

param rawDataLakeAccountName string
param rawDataLakeAccountID string
param curatedDataLakeAccountName string
param rawDataLakeZoneContainerNames array
param curatedDataLakeZoneContainerNames array

param eventHubNamespaceName string
param eventHubName string
param eventHubPartitionCount int

param textAnalyticsAccountName string
param anomalyDetectorAccountName string

param synapseSparkPoolID string
param synapseSparkPoolName string
param synapseWorkspaceID string
param synapseWorkspaceName string

var storageEnvironmentDNS = environment().suffixes.storage

//Key Vault Access Policy for Synapse
module m_KeyVaultSynapseAccessPolicy 'KeyVaultSynapseAccessPolicy.bicep' = {
  name: 'KeyVaultSynapseAccessPolicy'
  params: {
    keyVaultName: keyVaultName
    synapseWorkspaceIdentityPrincipalID: synapseWorkspaceIdentityPrincipalID
  }
}

//Key Vault Access Policy for Purview
module m_KeyVaultPurviewAccessPolicy 'KeyVaultPurviewAccessPolicy.bicep' = if (ctrlDeployPurview == true) {
  name: 'KeyVaultPurviewAccessPolicy'
  dependsOn:[
    m_KeyVaultSynapseAccessPolicy
  ]
  params:{
    keyVaultName: keyVaultName
    purviewIdentityPrincipalID: purviewIdentityPrincipalID
  }
}

resource r_textAnalytics 'Microsoft.CognitiveServices/accounts@2021-10-01' existing = {
  name: textAnalyticsAccountName
}

resource r_anomalyDetector 'Microsoft.CognitiveServices/accounts@2021-10-01' existing = {
  name: anomalyDetectorAccountName
}

//Reference existing Key Vault created by CoreServicesDeploy.bicep
resource r_keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

resource r_textAnalyticsAccountKey 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = if(ctrlDeployAI == true) {
  name:'${textAnalyticsAccountName}-Key'
  parent: r_keyVault
  properties:{
    value:  ctrlDeployAI ? listKeys(r_textAnalytics.id, r_textAnalytics.apiVersion).key1 : ''
  }
}

resource r_anomalyDetectorAccountKey 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = if(ctrlDeployAI == true) {
  name:'${anomalyDetectorAccountName}-Key'
  parent: r_keyVault
  properties:{
    value: ctrlDeployAI ? listKeys(r_anomalyDetector.id, r_anomalyDetector.apiVersion).key1 : ''
  }
}

resource r_synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
  name: synapseWorkspaceName

  resource r_workspaceAADAdmin 'administrators' = {
    name:'activeDirectory'
    properties:{
      administratorType:'ActiveDirectory'
      tenantId: subscription().tenantId
      sid: uamiPrincipalID
    }
  }
}

//Azure Machine Learning Datastores
resource r_azureMLWorkspace 'Microsoft.MachineLearningServices/workspaces@2021-07-01' existing = {
  name: azureMLWorkspaceName

  //Raw Data Lake Datastores
  resource r_azureMLRawDataLakeStores 'datastores@2021-03-01-preview' = [for containerName in rawDataLakeZoneContainerNames: if(ctrlDeployAI == true) {
    name: '${rawDataLakeAccountName}_${containerName}'
    properties: {
      contents: {
        contentsType:'AzureDataLakeGen2'
        accountName: rawDataLakeAccountName
        containerName: containerName
        credentials: {
          credentialsType: 'None'
        }
        endpoint: storageEnvironmentDNS
        protocol: 'https'
      }
    }
  }]

  //Curated Data Lake Datastores
  resource r_azureMLCuratedDataLakeStores 'datastores@2021-03-01-preview' = [for containerName in curatedDataLakeZoneContainerNames: if(ctrlDeployAI == true) {
    name: '${curatedDataLakeAccountName}_${containerName}'
    properties: {
      contents: {
        contentsType:'AzureDataLakeGen2'
        accountName: curatedDataLakeAccountName
        containerName: containerName
        credentials: {
          credentialsType: 'None'
        }
        endpoint: storageEnvironmentDNS
        protocol: 'https'
      }
    }
  }]
}

resource r_azureMLSynapseSparkCompute 'Microsoft.MachineLearningServices/workspaces/computes@2021-04-01' = if(ctrlDeployAI == true && ctrlSynapseDeploySparkPool == true) {
  parent: r_azureMLWorkspace
  name: synapseSparkPoolName
  location: resourceLocation
  properties:{
    computeType:'SynapseSpark'
    resourceId: ctrlSynapseDeploySparkPool ? synapseSparkPoolID : ''
  }
}

resource r_azureMLSynapseLinkedService 'Microsoft.MachineLearningServices/workspaces/linkedServices@2020-09-01-preview' = if(ctrlDeployAI == true) {
  parent: r_azureMLWorkspace
  name: synapseWorkspaceName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    linkedServiceResourceId: synapseWorkspaceID
  }
}

//Event Hub Capture
resource r_eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: eventHubNamespaceName

  resource r_eventHub 'eventhubs' = if(ctrlDeployStreaming == true && ctrlStreamIngestionService == 'eventhub') {
    name: eventHubName
    properties:{
      messageRetentionInDays:1
      partitionCount:eventHubPartitionCount
      captureDescription:{
        enabled:true
        skipEmptyArchives: true
        encoding: 'Avro'
        intervalInSeconds: 300
        sizeLimitInBytes: 314572800
        destination: {
          name: 'EventHubArchive.AzureBlockBlob'
          properties: {
            storageAccountResourceId: rawDataLakeAccountID
            blobContainer: 'raw'
            archiveNameFormat: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
          }
        }
      }
    }
  }
}

output azureMLSynapseLinkedServicePrincipalID string = ctrlDeployAI ? r_azureMLSynapseLinkedService.identity.principalId : ''
