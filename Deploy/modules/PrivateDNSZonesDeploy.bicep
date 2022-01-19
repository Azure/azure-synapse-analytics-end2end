
param vNetID string
param vNetName string

param ctrlDeployPurview bool
param ctrlDeployAI bool
param ctrlDeployStreaming bool
//param crtlDeployDataShare bool


var environmentStorageDNS = environment().suffixes.storage

//Private DNS Zones required for Storage DFS Private Link: privatelink.dfs.core.windows.net
//Required for Azure Data Lake Gen2
module m_privateDNSZoneStorageDFS './PrivateDNSZone.bicep' = {
  name: 'PrivateDNSZoneStorageDFS'
  params: {
    dnsZoneName: 'privatelink.dfs.${environmentStorageDNS}'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Private DNS Zones required for Storage Blob Private Link: privatelink.blob.core.windows.net
//Required for Purview, Azure ML
module m_privateDNSZoneStorageBlob 'PrivateDNSZone.bicep' = if (ctrlDeployPurview == true || ctrlDeployAI == true){
  name: 'PrivateDNSZoneStorageBlob'
  params: {
    dnsZoneName: 'privatelink.blob.${environmentStorageDNS}'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Private DNS Zones required for Storage Queue Private Link: privatelink.queue.core.windows.net
//Required for Purview
module m_privateDNSZoneStorageQueue 'PrivateDNSZone.bicep' = if (ctrlDeployPurview == true) {
  name: 'PrivateDNSZoneStorageQueue'
  params: {
    dnsZoneName: 'privatelink.queue.${environmentStorageDNS}'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Private DNS Zones required for Storage File Private Link: privatelink.file.core.windows.net
//Required for Azure ML Storage Account
module m_privateDNSZoneStorageFile 'PrivateDNSZone.bicep' = if (ctrlDeployAI == true) {
  name: 'PrivateDNSZoneStorageFile'
  params: {
    dnsZoneName: 'privatelink.file.${environmentStorageDNS}'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Private DNS Zones required for Synapse Private Link: privatelink.sql.azuresynapse.net
//Required for Synapse
module m_privateDNSZoneSynapseSQL './PrivateDNSZone.bicep' = {
  name: 'PrivateDNSZoneSynapseSQL'
  params: {
    dnsZoneName: 'privatelink.sql.azuresynapse.net'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Private DNS Zones required for Synapse Private Link: privatelink.dev.azuresynapse.net
//Required for Synapse
module m_privateDNSZoneSynapseDev './PrivateDNSZone.bicep' = {
  name: 'PrivateDNSZoneSynapseDev'
  params: {
    dnsZoneName: 'privatelink.dev.azuresynapse.net'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Private DNS Zones required for Synapse Private Link: privatelink.azuresynapse.net
//Required for Synapse
module m_privateDNSZoneSynapseWeb './PrivateDNSZone.bicep' = {
  name: 'PrivateDNSZoneSynapseWeb'
  params: {
    dnsZoneName: 'privatelink.azuresynapse.net'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Private DNS Zones required for Synapse Private Link: privatelink.vaultcore.azure.net
//Required for KeyVault
module m_privateDNSZoneKeyVault './PrivateDNSZone.bicep' = {
  name: 'PrivateDNSZoneKeyVault'
  params: {
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Private DNS Zones required for EventHubs: privatelink.servicebus.windows.net
//Required for Purview Event Hubs
module m_privateDNSZoneServiceBus './PrivateDNSZone.bicep' = if(ctrlDeployPurview == true || ctrlDeployStreaming == true){
  name: 'PrivateDNSZonePurviewServiceBus'
  params: {
    dnsZoneName: 'privatelink.servicebus.windows.net'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Purview Account private endpoint
module m_privateDNSZonePurviewAccount 'PrivateDNSZone.bicep' = if(ctrlDeployPurview == true) {
  name: 'PrivateDNSZonePurviewAccount'
  params: {
    dnsZoneName: 'privatelink.purview.azure.com'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Purview Portal private endpoint
module m_privateDNSZonePurviewPortal 'PrivateDNSZone.bicep' = if(ctrlDeployPurview == true) {
  name: 'PrivateDNSZonePurviewPortal'
  params: {
    dnsZoneName: 'privatelink.purviewstudio.azure.com'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Azure Container Registry DNS Zone privatelink.azurecr.io
//Required by Azure ML
module m_privateDNSZoneACR 'PrivateDNSZone.bicep' = if(ctrlDeployAI == true) {
  name: 'PrivateDNSZoneContainerRegistry'
  params: {
    dnsZoneName: 'privatelink.azurecr.io'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Azure Machine Learning Workspace DNS Zone: privatelink.api.azureml.ms
//Required by Azure ML
module m_privateDNSZoneAzureMLAPI 'PrivateDNSZone.bicep' = if(ctrlDeployAI == true) {
  name: 'PrivateDNSZoneAzureMLAPI'
  params: {
    dnsZoneName: 'privatelink.api.azureml.ms'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Azure Machine Learning Workspace DNS Zone: privatelink.notebooks.azure.net
//Required by Azure ML
module m_privateDNSZoneAzureMLNotebooks 'PrivateDNSZone.bicep' = if(ctrlDeployAI == true) {
  name: 'PrivateDNSZoneAzureMLNotebook'
  params: {
    dnsZoneName: 'privatelink.notebooks.azure.net'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//IoTHub DNS Zone: privatelink.azure-devices.net
//Required by IoTHub
module m_privateDNSZoneIoTHub 'PrivateDNSZone.bicep' = if(ctrlDeployStreaming == true) {
  name: 'PrivateDNSZoneIoTHub'
  params: {
    dnsZoneName: 'privatelink.azure-devices.net'
    vNetID: vNetID
    vNetName: vNetName
  }
}

//Cognitive Services DNS Zone: privatelink.cognitiveservices.azure.com
//Required by Cognitive Services
module m_privateDNSZoneCognitiveService 'PrivateDNSZone.bicep' = if(ctrlDeployAI == true) {
  name: 'PrivateDNSZoneCognitiveService'
  params: {
    dnsZoneName: 'privatelink.cognitiveservices.azure.com'
    vNetID: vNetID
    vNetName: vNetName
  }
}

output storageDFSPrivateDNSZoneID string = m_privateDNSZoneStorageDFS.outputs.dnsZoneID
output storageBlobPrivateDNSZoneID string = ctrlDeployPurview == true || ctrlDeployAI == true ? m_privateDNSZoneStorageBlob.outputs.dnsZoneID: ''
output storageQueuePrivateDNSZoneID string = ctrlDeployPurview ? m_privateDNSZoneStorageQueue.outputs.dnsZoneID : ''
output storageFilePrivateDNSZoneID string = ctrlDeployAI ? m_privateDNSZoneStorageFile.outputs.dnsZoneID : ''
output synapseSQLPrivateDNSZoneID string = m_privateDNSZoneSynapseSQL.outputs.dnsZoneID
output synapseDevPrivateDNSZoneID string = m_privateDNSZoneSynapseDev.outputs.dnsZoneID
output synapseWebPrivateDNSZoneID string = m_privateDNSZoneSynapseWeb.outputs.dnsZoneID
output keyVaultPrivateDNSZoneID string = m_privateDNSZoneKeyVault.outputs.dnsZoneID
output serviceBusPrivateDNSZoneID string = ctrlDeployPurview == true || ctrlDeployStreaming == true ? m_privateDNSZoneServiceBus.outputs.dnsZoneID : ''
output purviewAccountPrivateDNSZoneID string = ctrlDeployPurview ? m_privateDNSZonePurviewAccount.outputs.dnsZoneID : ''
output acrPrivateDNSZoneID string = ctrlDeployAI ? m_privateDNSZoneACR.outputs.dnsZoneID : ''
output azureMLAPIPrivateDNSZoneID string = ctrlDeployAI ? m_privateDNSZoneAzureMLAPI.outputs.dnsZoneID : ''
output azureMLNotebooksPrivateDNSZoneID string = ctrlDeployAI ? m_privateDNSZoneAzureMLNotebooks.outputs.dnsZoneID : ''
output iotHubPrivateDNSZoneID string = ctrlDeployStreaming ? m_privateDNSZoneIoTHub.outputs.dnsZoneID : ''
output cognitiveServicePrivateDNSZoneID string = ctrlDeployAI ? m_privateDNSZoneCognitiveService.outputs.dnsZoneID : ''
