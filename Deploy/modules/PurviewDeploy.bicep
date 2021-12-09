param deploymentMode string
param resourceLocation string

param ctrlDeployPrivateDNSZones bool

param purviewAccountName string 
param purviewManagedRGName string 

param subnetID string
param uamiPrincipalID string

//RBAC Role IDs
var azureRBACReaderRoleID = 'acdd72a7-3385-48ef-bd42-f606fba81ae7' //Reader Role
var azureRBACPurviewDataSourceAdministratorRoleID = '200bba9e-f0c8-430f-892b-6f0794863803' //Purview Data Source Administrator Role
var environmentStorageDNS = environment().suffixes.storage

//Purview Account
resource r_purviewAccount 'Microsoft.Purview/accounts@2020-12-01-preview' = {
  name: purviewAccountName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    //publicNetworkAccess: (deploymentMode == 'vNet') ? 'Disabled' : 'Enabled'
    publicNetworkAccess: 'Enabled' //Required for PostDeployment Scripts Purview API calls.
    managedResourceGroupName: purviewManagedRGName
  }
}

//Purview Ingestion endpoint: Blob
resource r_privateDNSZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.blob.${environmentStorageDNS}'
}

//Purview Ingestion endpoint: Queue
resource r_privateDNSZoneStorageQueue 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.queue.${environmentStorageDNS}'
}

//Purview Ingestion endpoint: Event Hub Namespace
resource r_privateDNSZoneServiceBus 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.servicebus.windows.net'
}

//Purview Account and Portal private endpoints
resource r_privateDNSZonePurviewAccount 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.purview.azure.com'
}

resource r_privateDNSZonePurviewPortal 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.purviewstudio.azure.com'
}

module m_purviewBlobPrivateLink 'PrivateEndpoint.bicep' = if(deploymentMode == 'vNet') {
  name: 'purviewBlobPrivateLink'
  params: {
    groupID: 'blob'
    privateEndpoitName: '${r_purviewAccount.name}-blob'
    privateLinkServiceId: r_purviewAccount.properties.managedResources.storageAccount
    resourceLocation: resourceLocation
    subnetID: subnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
    privateDNSZoneConfigs: [
      {
        name:'privatelink-blob-core-windows-net'
        properties:{
          privateDnsZoneId: r_privateDNSZoneBlob.id
        }
      }
    ]
  }
}

module m_purviewQueuePrivateLink 'PrivateEndpoint.bicep' = if(deploymentMode == 'vNet') {
  name: 'PurviewQueuePrivateLink'
  params: {
    groupID: 'queue'
    privateEndpoitName: '${r_purviewAccount.name}-queue'
    privateLinkServiceId: r_purviewAccount.properties.managedResources.storageAccount
    resourceLocation: resourceLocation
    subnetID: subnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
    privateDNSZoneConfigs:[
      {
        name:'privatelink-queue-core-windows-net'
        properties:{
          privateDnsZoneId: r_privateDNSZoneStorageQueue.id
        }
      }
    ]
  }
}

module m_purviewEventHubPrivateLink 'PrivateEndpoint.bicep' = if(deploymentMode == 'vNet') {
  name: 'PurviewEventHubPrivateLink'
  params: {
    groupID: 'namespace'
    privateEndpoitName: '${r_purviewAccount.name}-namespace'
    privateLinkServiceId: r_purviewAccount.properties.managedResources.eventHubNamespace
    resourceLocation: resourceLocation
    subnetID: subnetID
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

module m_purviewAccountPrivateLink 'PrivateEndpoint.bicep' = if(deploymentMode == 'vNet') {
  name: 'PurviewAccountPrivateLink'
  params: {
    groupID: 'account'
    privateEndpoitName: '${r_purviewAccount.name}-account'
    privateLinkServiceId: r_purviewAccount.id
    resourceLocation: resourceLocation
    subnetID: subnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
    privateDNSZoneConfigs: [
      {
        name:'privatelink-purview-azure-com-account'
        properties:{
          privateDnsZoneId: r_privateDNSZonePurviewAccount.id
        }
      }
    ]
  }
}

module m_purviewPortalPrivateLink 'PrivateEndpoint.bicep' = if(deploymentMode == 'vNet') {
  name: 'PurviewPortalPrivateLink'
  params: {
    groupID: 'portal'
    privateEndpoitName: '${r_purviewAccount.name}-portal'
    privateLinkServiceId: r_purviewAccount.id
    resourceLocation: resourceLocation
    subnetID: subnetID
    deployDNSZoneGroup: ctrlDeployPrivateDNSZones
    privateDNSZoneConfigs: [
      {
        name:'privatelink-purview-azure-com-portal'
        properties:{
          privateDnsZoneId: r_privateDNSZonePurviewPortal.id
        }
      }
    ]
  }
}

//Assign Reader Role to Purview MSI in the Resource Group as per https://docs.microsoft.com/en-us/azure/purview/register-scan-synapse-workspace
resource r_purviewRGReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().name, purviewAccountName, 'Reader')
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACReaderRoleID)
    principalId: r_purviewAccount.identity.principalId
    principalType:'ServicePrincipal'
  }
}

//Assign Purview Data Source Administrator Role to UAMI in the Purview Account. UAMI needs it so it can make calls to Purview APIs from post deployment script.
resource r_purviewDataSourceAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(purviewAccountName, uamiPrincipalID)
  scope: r_purviewAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACPurviewDataSourceAdministratorRoleID)
    principalId: uamiPrincipalID
    principalType:'ServicePrincipal'
  }
}


output purviewAccountID string = r_purviewAccount.id
output purviewAccountName string = r_purviewAccount.name
output purviewIdentityPrincipalID string = r_purviewAccount.identity.principalId
output purviewScanEndpoint string = r_purviewAccount.properties.endpoints.scan
output purviewAPIVersion string = r_purviewAccount.apiVersion
