param networkIsolationMode string
param subNetID string
param resourceLocation string
param eventHubNamespaceName string
param eventHubSku string
param iotHubName string
param iotHubSku string = 'F1'
param streamAnalyticsJobName string
param streamAnalyticsJobSku string

@allowed([
  'eventhub'
  'iothub'
])
param ctrlStreamIngestionService string = 'eventhub'

//Azure Event Hubs Data Owner Role ID
var azureEventHubsDataOwnerRABCRoleID = 'f526a384-b230-433a-b45c-95f59c4a2dec' //https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-event-hubs-data-owner

//Azure IoT Hubs Data Reader Role ID
var azureIoTHubDataReaderRBACRoleID = 'b447c946-2db7-41ec-983d-d8bf3b1c77e3'

//Event Hubs
resource r_eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = if(ctrlStreamIngestionService == 'eventhub') {
  name: eventHubNamespaceName
  location: resourceLocation
  sku:{
    name:eventHubSku
    tier:eventHubSku
    capacity:1
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource networkAccessRules 'networkRuleSets' = if(networkIsolationMode == 'vNet') {
    name: 'default'
    properties:{
      publicNetworkAccess: 'Enabled'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          subnet:{
            id: subNetID
          }
          ignoreMissingVnetServiceEndpoint: true
        }
      ]
      trustedServiceAccessEnabled: true //Required by Stream Analytics jobs.
    }
  }
}

resource r_iotHub 'Microsoft.Devices/IotHubs@2021-07-01' = if(ctrlStreamIngestionService == 'iothub') {
  name: iotHubName
  location: resourceLocation
  sku: {
    name: iotHubSku
    capacity: 1
  }
  properties:{
    publicNetworkAccess: (networkIsolationMode == 'vNet') ? 'Disabled' : 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource r_streamAnalyticsJob 'Microsoft.StreamAnalytics/streamingjobs@2020-03-01' = {
  name: streamAnalyticsJobName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    sku:{
      name:streamAnalyticsJobSku
    }
    jobType:'Cloud'
  }
}

//Assign Event Hubs Data Owner role to Azure Stream Analytics in the EventHubs namespace as per https://docs.microsoft.com/en-us/azure/stream-analytics/event-hubs-managed-identity#grant-the-stream-analytics-job-permissionsto-access-the-event-hub
resource r_azureStreamAnalyticsEventHubsDataReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (ctrlStreamIngestionService == 'eventhub') {
  name: guid(eventHubNamespaceName, streamAnalyticsJobName, 'Event Hubs Data Receiver')
  scope:r_eventHubNamespace
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureEventHubsDataOwnerRABCRoleID)
    principalId: ctrlStreamIngestionService == 'eventhub' ? r_streamAnalyticsJob.identity.principalId : ''
    principalType:'ServicePrincipal'
  }
}

//Assign IoT Hub Data Reader role to Azure Stream Analytics in the IoTHub as per https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-dev-guide-azure-ad-rbac#manage-access-to-iot-hub-by-using-azure-rbac-role-assignment
resource r_azureIoTHubDataReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (ctrlStreamIngestionService == 'iothub') {
  name: guid(iotHubName, streamAnalyticsJobName, 'IoT Hub Data Receiver')
  scope:r_iotHub
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureIoTHubDataReaderRBACRoleID)
    principalId: (ctrlStreamIngestionService == 'iothub') ? r_streamAnalyticsJob.identity.principalId : ''
    principalType:'ServicePrincipal'
  }
}

output streamAnalyticsIdentityPrincipalID string = r_streamAnalyticsJob.identity.principalId
output streamAnalyticsJobID string = r_streamAnalyticsJob.id
output streamAnalyticsJobName string = r_streamAnalyticsJob.name
output iotHubName string = (ctrlStreamIngestionService == 'iothub') ? r_iotHub.name : ''
output iotHubID string = (ctrlStreamIngestionService == 'iothub') ? r_iotHub.id : ''
output iotHubPrincipalID string = (ctrlStreamIngestionService == 'iothub') ? r_iotHub.identity.principalId : ''
output eventHubNamespaceName string = (ctrlStreamIngestionService == 'eventhub') ? r_eventHubNamespace.name : ''
output eventHubNamespaceID string = (ctrlStreamIngestionService == 'eventhub') ? r_eventHubNamespace.id : ''
