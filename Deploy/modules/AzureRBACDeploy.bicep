param ctrlDeployPurview bool
param ctrlDeployAI bool
param ctrlDeployDataShare bool 
param ctrlDeployStreaming bool

param rawDataLakeAccountName string
param curatedDataLakeAccountName string
param azureMLWorkspaceName string
param purviewAccountName string
param synapseWorkspaceName string
param synapseWorkspaceIdentityPrincipalID string
param azureMLSynapseLinkedServicePrincipalID string
param purviewIdentityPrincipalID string
param UAMIPrincipalID string
param dataShareAccountPrincipalID string
param streamAnalyticsIdentityPrincipalID string
param ctrlStreamingIngestionService string
param iotHubPrincipalID string


var azureRBACStorageBlobDataReaderRoleID = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' //Storage Blob Data Reader Role: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader
var azureRBACStorageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor Role: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
var azureRBACContributorRoleID = 'b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor
var azureRBACOwnerRoleID = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' //Owner: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner
var azureRBACReaderRoleID = 'acdd72a7-3385-48ef-bd42-f606fba81ae7' //Reader: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader

//Reference existing resources for permission assignment scope
resource r_rawDataLakeStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: rawDataLakeAccountName
}

resource r_curatedDataLakeStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: curatedDataLakeAccountName
}

resource r_azureMLWorkspace 'Microsoft.MachineLearningServices/workspaces@2021-07-01' existing = {
  name: azureMLWorkspaceName
}

resource r_synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
  name: synapseWorkspaceName
}

resource r_purviewAccount 'Microsoft.Purview/accounts@2021-07-01' existing = {
  name: purviewAccountName
}

//Assign Owner Role to UAMI in the Synapse Workspace. UAMI needs to be Owner so it can assign itself as Synapse Admin and create resources in the Data Plane.
resource r_synapseWorkspaceOwner 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid('cbe28037-09a6-4b35-a751-8dfd3f03f59d', subscription().subscriptionId, resourceGroup().id)
  scope: r_synapseWorkspace
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACOwnerRoleID)
    principalId: UAMIPrincipalID
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Reader Role to Purview MSI in the Resource Group as per https://docs.microsoft.com/en-us/azure/purview/register-scan-synapse-workspace
resource r_purviewRGStorageBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if (ctrlDeployPurview == true) {
  name: guid('3f2019ca-ce91-4153-920a-19e6dae191a8', subscription().subscriptionId, resourceGroup().id)
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataReaderRoleID)
    principalId: ctrlDeployPurview ? purviewIdentityPrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Deployment script UAMI is set as Resource Group owner so it can have authorisation to perform post deployment tasks
resource r_deploymentScriptUAMIRGOwner 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid('139d07dd-a26c-4b29-9619-8f70ea215795', subscription().subscriptionId, resourceGroup().id)
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACOwnerRoleID)
    principalId: UAMIPrincipalID
    principalType:'ServicePrincipal'
  }
}

//Azure Synaspe MSI needs to have Contributor permissions in the Azure ML workspace.
//https://docs.microsoft.com/en-us/azure/synapse-analytics/machine-learning/quickstart-integrate-azure-machine-learning#give-msi-permission-to-the-azure-ml-workspace
resource r_synapseAzureMLContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if(ctrlDeployAI == true) {
  name: guid('dfe59492-dd91-45d5-804a-ebf18e820dcc', subscription().subscriptionId, resourceGroup().id)
  scope: r_azureMLWorkspace
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACContributorRoleID)
    principalId: synapseWorkspaceIdentityPrincipalID
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Reader Role to Azure ML MSI in the Raw Data Lake Account as per https://docs.microsoft.com/en-us/azure/machine-learning/how-to-identity-based-data-access
resource r_azureMLRawStorageBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if(ctrlDeployAI == true) {
  name: guid('be61ada6-1a00-47ff-8027-81b1b6c7b82a', subscription().subscriptionId, resourceGroup().id)
  scope: r_rawDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataReaderRoleID)
    principalId: ctrlDeployAI ? azureMLSynapseLinkedServicePrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Reader Role to Azure ML MSI in the Curated Data Lake Account as per https://docs.microsoft.com/en-us/azure/machine-learning/how-to-identity-based-data-access
resource r_azureMLCuratedStorageBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if(ctrlDeployAI == true) {
  name: guid('57116cd9-7bcb-402c-8739-97a8b4c6afad', subscription().subscriptionId, resourceGroup().id)
  scope: r_curatedDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataReaderRoleID)
    principalId: ctrlDeployAI ? azureMLSynapseLinkedServicePrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Reader Role to Azure Data Share in the Raw Data Lake Account as per https://docs.microsoft.com/en-us/azure/data-share/concepts-roles-permissions
resource r_azureDataShareRawStorageBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if (ctrlDeployDataShare == true) {
  name: guid('bbcbc4e3-e2bb-4cde-97c8-02636e6f1632', subscription().subscriptionId, resourceGroup().id)
  scope: r_rawDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataReaderRoleID)
    principalId: ctrlDeployDataShare ? dataShareAccountPrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Reader Role to Azure Data Share in the Curated Data Lake Account as per https://docs.microsoft.com/en-us/azure/data-share/concepts-roles-permissions
resource r_azureDataShareCuratedStorageBlobDataReader 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if (ctrlDeployDataShare == true) {
  name: guid('d0d58921-3185-483b-892f-bbae0210fee9', subscription().subscriptionId, resourceGroup().id)
  scope: r_curatedDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataReaderRoleID)
    principalId: ctrlDeployDataShare ? dataShareAccountPrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Contributor Role to Azure Stream Analytics in the Raw Data Lake Account 
//https://docs.microsoft.com/en-us/azure/stream-analytics/blob-output-managed-identity#grant-access-via-the-azure-portal
resource r_streamAnalyticsRawStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if (ctrlDeployStreaming == true) {
  name: guid('5411c956-6918-4e05-b23b-a8260d63799c', subscription().subscriptionId, resourceGroup().id)
  scope: r_rawDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: ctrlDeployStreaming ? streamAnalyticsIdentityPrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Contributor Role to Azure Stream Analytics in the Curated Data Lake Account 
//https://docs.microsoft.com/en-us/azure/stream-analytics/blob-output-managed-identity#grant-access-via-the-azure-portal
resource r_streamAnalyticsCuratedStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if (ctrlDeployStreaming == true) {
  name: guid('a4c67752-b33e-492c-a62f-1514dd1f8364', subscription().subscriptionId, resourceGroup().id)
  scope: r_curatedDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: ctrlDeployStreaming ? streamAnalyticsIdentityPrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Contributor Role to IoTHub in the Raw Data Lake Account 
resource r_iotHubRawStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if (ctrlDeployStreaming == true && ctrlStreamingIngestionService == 'iothub') {
  name: guid('67c87aaa-7c65-4ca0-96bd-cc5ae82bd2f4', subscription().subscriptionId, resourceGroup().id)
  scope: r_rawDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: (ctrlDeployStreaming == true && ctrlStreamingIngestionService == 'iothub') ? iotHubPrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Contributor Role to IoTHub in the Curated Data Lake Account 
resource r_iotHubCuratedStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if (ctrlDeployStreaming == true && ctrlStreamingIngestionService == 'iothub') {
  name: guid('f1f3d703-c621-448f-a658-ce53ddbd81b0', subscription().subscriptionId, resourceGroup().id)
  scope: r_curatedDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: (ctrlDeployStreaming == true && ctrlStreamingIngestionService == 'iothub') ? iotHubPrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Contributor Role to Synapse Workspace in the Raw Data Lake Account as per https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions#grant-the-managed-identity-permissions-to-adls-gen2-storage-account
resource r_synapseWorkspaceRawStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid('a1fb98aa-4c53-4a4d-951f-3ac730a27a5b', subscription().subscriptionId, resourceGroup().id)
  scope: r_rawDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: synapseWorkspaceIdentityPrincipalID
    principalType:'ServicePrincipal'
  }
}

//Assign Storage Blob Data Contributor Role to Synapse Workspace in the Curated Data Lake Account as per https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions#grant-the-managed-identity-permissions-to-adls-gen2-storage-account
resource r_synapseWorkspaceCuratedStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid('4354d861-488d-4395-b018-2cc2baa9e491', subscription().subscriptionId, resourceGroup().id)
  scope: r_curatedDataLakeStorageAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: synapseWorkspaceIdentityPrincipalID
    principalType:'ServicePrincipal'
  }
}

//Assign Purview the Reader role in the Synapse Workspace as per https://docs.microsoft.com/en-us/azure/purview/register-scan-synapse-workspace#authentication-for-enumerating-serverless-sql-database-resources
resource r_purviewSynapseReader 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if(ctrlDeployPurview == true) {
  name: guid('f4191dd4-2d87-47c0-9f38-d3d24cc13f5c', subscription().subscriptionId, resourceGroup().id)
  scope: r_synapseWorkspace
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACReaderRoleID)
    principalId: ctrlDeployPurview ? purviewIdentityPrincipalID : ''
    principalType:'ServicePrincipal'
  }
}

