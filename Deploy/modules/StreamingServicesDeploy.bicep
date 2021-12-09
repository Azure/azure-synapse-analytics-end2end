param deploymentMode string
param resourceLocation string
param eventHubNamespaceName string
param eventHubName string
param eventHubSku string
param eventHubPartitionCount int
param streamAnalyticsJobName string
param streamAnalyticsJobSku string
param dataLakeStorageAccountID string
param vNetSubnetID string
param ctrlDeployPrivateDNSZones bool

//Purview Ingestion endpoint: Event Hub Namespace
resource r_privateDNSZoneServiceBus 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.servicebus.windows.net'
}

resource r_eventHubNamespace 'Microsoft.EventHub/namespaces@2017-04-01' = {
  name: eventHubNamespaceName
  location: resourceLocation
  sku:{
    name:eventHubSku
    tier:eventHubSku
    capacity:1
  }

  resource r_eventHub 'eventhubs' = {
    name:eventHubName
    properties:{
      messageRetentionInDays:7
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
            storageAccountResourceId: dataLakeStorageAccountID
            blobContainer: 'raw'
            archiveNameFormat: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
          }
        }
      }
    }
  }
}

module m_purviewEventHubPrivateLink 'PrivateEndpoint.bicep' = if(deploymentMode == 'vNet') {
  name: 'PurviewEventHubPrivateLink'
  params: {
    groupID: 'namespace'
    privateEndpoitName: '${r_eventHubNamespace.name}-namespace'
    privateLinkServiceId: r_eventHubNamespace.id
    resourceLocation: resourceLocation
    subnetID: vNetSubnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
    privateDNSZoneConfigs: [
      {
        name:'privatelink-servicebus-windows-net'
        properties:{
          privateDnsZoneId: r_privateDNSZoneServiceBus.id
        }
      }
    ]
  }
}

resource r_streamAnalyticsJob 'Microsoft.StreamAnalytics/streamingjobs@2017-04-01-preview' = {
  name: streamAnalyticsJobName
  location: resourceLocation
  properties:{
    sku:{
      name:streamAnalyticsJobSku
    }
  }
}
