param resourceLocation string
param purviewAccountName string 
param purviewManagedRGName string 

//RBAC Role IDs
var azureRBACReaderRoleID = 'acdd72a7-3385-48ef-bd42-f606fba81ae7' //Reader Role

//Purview Account
resource r_purviewAccount 'Microsoft.Purview/accounts@2020-12-01-preview' = {
  name: purviewAccountName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    publicNetworkAccess: 'Enabled' //Required for PostDeployment Scripts Purview API calls. Post Deployment Script to disable it if networkIsolationMode == vNet.
    managedResourceGroupName: purviewManagedRGName
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

output purviewAccountID string = r_purviewAccount.id
output purviewAccountName string = r_purviewAccount.name
output purviewIdentityPrincipalID string = r_purviewAccount.identity.principalId
output purviewScanEndpoint string = r_purviewAccount.properties.endpoints.scan
output purviewAPIVersion string = r_purviewAccount.apiVersion
output purviewManagedStorageAccountID string = r_purviewAccount.properties.managedResources.storageAccount
output purviewManagedEventHubNamespaceID string = r_purviewAccount.properties.managedResources.eventHubNamespace
