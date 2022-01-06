param networkIsolationMode string
param resourceLocation string

param rawDataLakeAccountName string
param curatedDataLakeAccountName string
param rawDataLakeZoneContainerNames array
param curatedDataLakeZoneContainerNames array

param synapseWorkspaceResourceID string
param dataShareResourceID string
param streamAnalyticsJobResourceID string
param purviewAccountResourceID string
param azureMLWorkspaceResourceID string
param anomalyDetectorAccountResourceID string
param languageServiceAccountResourceID string
param iotHubResourceID string
param ctrlDeployStreaming bool 

@allowed([
  'eventhub'
  'iothub'
])
param ctrlStreamIngestionService string = 'eventhub'

//Data Lake account Network Access Rules
var synapseAccessRule = (synapseWorkspaceResourceID == '') ? [] : [
  {
    tenantId: subscription().tenantId
    resourceId: synapseWorkspaceResourceID
  }
]

var dataShareAccessRule = (dataShareResourceID == '') ? [] : [
  {
    tenantId: subscription().tenantId
    resourceId: dataShareResourceID
  }
]

var streamAnalyticsJobAccessRule = (streamAnalyticsJobResourceID == '') ? [] : [
  {
    tenantId: subscription().tenantId
    resourceId: streamAnalyticsJobResourceID
  }
]

var purviewAccessRule = (purviewAccountResourceID == '') ? [] : [
  {
    tenantId: subscription().tenantId
    resourceId: purviewAccountResourceID
  }
]

var azureMLAccessRule = (azureMLWorkspaceResourceID == '') ? [] : [
  {
    tenantId: subscription().tenantId
    resourceId: azureMLWorkspaceResourceID
  }
]

var anomalyDetectorAccessRule = (anomalyDetectorAccountResourceID == '') ? [] : [
  {
    tenantId: subscription().tenantId
    resourceId: anomalyDetectorAccountResourceID
  }
]

var languageServiceAccessRule = (languageServiceAccountResourceID == '') ? [] : [
  {
    tenantId: subscription().tenantId
    resourceId: languageServiceAccountResourceID
  }
]

var iotHubAccessRule = (iotHubResourceID == '') ? [] : [
  {
    tenantId: subscription().tenantId
    resourceId: iotHubResourceID
  }
]

var dataLakeresourceAccessRules = union(synapseAccessRule, dataShareAccessRule, streamAnalyticsJobAccessRule, purviewAccessRule, azureMLAccessRule, anomalyDetectorAccessRule, languageServiceAccessRule, iotHubAccessRule)

//Raw Data Lake Storage Account
resource r_rawDataLakeStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: rawDataLakeAccountName
  location: resourceLocation
  properties:{
    isHnsEnabled: true
    accessTier:'Hot'
    networkAcls: {
      defaultAction: (networkIsolationMode == 'vNet')? 'Deny' : 'Allow'
      //bypass: only required for EventHubs. All other services will have specific access rules defined in the resourceAccessRules element below.
      //Only EventHubs in the same subscription will have access to the storage account: https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal#trusted-access-for-resources-registered-in-your-subscription
      bypass: (ctrlDeployStreaming && ctrlStreamIngestionService == 'eventhub') ? 'AzureServices' : 'None' 
      resourceAccessRules: dataLakeresourceAccessRules
    }
  }
  kind:'StorageV2'
  sku: {
      name: 'Standard_GRS'
  }
}

//Curated Data Lake Storage Account
resource r_curatedDataLakeStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: curatedDataLakeAccountName
  location: resourceLocation
  properties:{
    isHnsEnabled: true
    accessTier:'Hot'
    networkAcls: {
      defaultAction: (networkIsolationMode == 'vNet')? 'Deny' : 'Allow'
      //bypass: only required for EventHubs. All other services will have specific access rules defined in the resourceAccessRules element below.
      //Only EventHubs in the same subscription will have access to the storage account: https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal#trusted-access-for-resources-registered-in-your-subscription
      bypass: (ctrlDeployStreaming && ctrlStreamIngestionService == 'eventhub') ? 'AzureServices' : 'None' 
      resourceAccessRules: dataLakeresourceAccessRules
    }
  }
  kind:'StorageV2'
  sku: {
      name: 'Standard_GRS'
  }
}

//Data Lake zone containers
resource r_rawDataLakeZoneContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for containerName in rawDataLakeZoneContainerNames: {
  name:'${r_rawDataLakeStorageAccount.name}/default/${containerName}'
}]

resource r_curatedDataLakeZoneContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for containerName in curatedDataLakeZoneContainerNames: {
  name:'${r_curatedDataLakeStorageAccount.name}/default/${containerName}'
}]

output rawDataLakeStorageAccountID string = r_rawDataLakeStorageAccount.id
output rawDataLakeStorageAccountName string = r_rawDataLakeStorageAccount.name
output curatedDataLakeStorageAccountID string = r_curatedDataLakeStorageAccount.id
output curatedDataLakeStorageAccountName string = r_curatedDataLakeStorageAccount.name
