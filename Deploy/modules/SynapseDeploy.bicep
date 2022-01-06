param networkIsolationMode string
param resourceLocation string

param ctrlDeploySynapseSQLPool bool
param ctrlDeploySynapseSparkPool bool
param ctrlDeploySynapseADXPool bool

param workspaceDataLakeAccountName string

param dataLakeSandpitZoneName string
param synapseDefaultContainerName string

param synapseWorkspaceName string
param synapseSqlAdminUserName string
param synapseSqlAdminPassword string
param synapseManagedRGName string
param synapseDedicatedSQLPoolName string
param synapseSQLPoolSKU string
param synapseSparkPoolName string
param synapseSparkPoolNodeSize string
param synapseSparkPoolMinNodeCount int
param synapseSparkPoolMaxNodeCount int
param synapseADXPoolName string
param synapseADXDatabaseName string
param synapseADXPoolEnableAutoScale bool
param synapseADXPoolMinSize int
param synapseADXPoolMaxSize int

param purviewAccountID string

var storageEnvironmentDNS = environment().suffixes.storage
var dataLakeStorageAccountUrl = 'https://${workspaceDataLakeAccountName}.dfs.${storageEnvironmentDNS}'
var azureRBACStorageBlobDataContributorRoleID = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor Role

//Data Lake Storage Account
resource r_workspaceDataLakeAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: workspaceDataLakeAccountName
  location: resourceLocation
  properties:{
    isHnsEnabled: true
    accessTier:'Hot'
    networkAcls: {
      defaultAction: (networkIsolationMode == 'vNet')? 'Deny' : 'Allow'
      bypass:'None'
      resourceAccessRules: [
        {
          tenantId: subscription().tenantId
          resourceId: r_synapseWorkspace.id
        }
    ]
    }
  }
  kind:'StorageV2'
  sku: {
      name: 'Standard_LRS'
  }
}

var privateContainerNames = [
  dataLakeSandpitZoneName
  synapseDefaultContainerName
]

resource r_dataLakePrivateContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for containerName in privateContainerNames: {
  name:'${r_workspaceDataLakeAccount.name}/default/${containerName}'
}]

//Synapse Workspace
resource r_synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name:synapseWorkspaceName
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    defaultDataLakeStorage:{
      accountUrl: dataLakeStorageAccountUrl
      filesystem: synapseDefaultContainerName
    }
    sqlAdministratorLogin: synapseSqlAdminUserName
    sqlAdministratorLoginPassword: synapseSqlAdminPassword
    //publicNetworkAccess: Post Deployment Script will disable public network access for vNet integrated deployments.
    managedResourceGroupName: synapseManagedRGName
    managedVirtualNetwork: (networkIsolationMode == 'vNet') ? 'default' : ''
    managedVirtualNetworkSettings: (networkIsolationMode == 'vNet')? {
      preventDataExfiltration:true
    }: null
    purviewConfiguration:{
      purviewResourceId: purviewAccountID
    }
  }

  //Dedicated SQL Pool
  resource r_sqlPool 'sqlPools' = if (ctrlDeploySynapseSQLPool == true){
    name: synapseDedicatedSQLPoolName
    location: resourceLocation
    sku:{
      name:synapseSQLPoolSKU
    }
    properties:{
      createMode:'Default'
      collation: 'SQL_Latin1_General_CP1_CI_AS'
    }
  }

  //Default Firewall Rules - Allow All Traffic
  resource r_synapseWorkspaceFirewallAllowAll 'firewallRules' = if (networkIsolationMode == 'default'){
    name: 'AllowAllNetworks'
    properties:{
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }

  //Firewall Allow Azure Sevices
  //Required for Post-Deployment Scripts
  resource r_synapseWorkspaceFirewallAllowAzure 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps'
    properties:{
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }

  //Set Synapse MSI as SQL Admin
  resource r_managedIdentitySqlControlSettings 'managedIdentitySqlControlSettings' = {
    name: 'default'
    properties:{
      grantSqlControlToManagedIdentity:{
        desiredState: 'Enabled'
      }
    }
  }

  //Spark Pool
  resource r_sparkPool 'bigDataPools' = if(ctrlDeploySynapseSparkPool == true){
    name: synapseSparkPoolName
    location: resourceLocation
    properties:{
      autoPause:{
        enabled:true
        delayInMinutes: 15
      }
      nodeSize: synapseSparkPoolNodeSize
      nodeSizeFamily:'MemoryOptimized'
      sparkVersion: '2.4'
      autoScale:{
        enabled:true
        minNodeCount: synapseSparkPoolMinNodeCount
        maxNodeCount: synapseSparkPoolMaxNodeCount
      }
    }
  }

  resource r_adxPool 'kustoPools@2021-06-01-preview' = if (ctrlDeploySynapseADXPool == true) {
    name: synapseADXPoolName
    location: resourceLocation
    sku: {
      capacity: 2
      name: 'Compute optimized'
      size: 'Extra small'
    }
    properties: {
      enablePurge: false
      workspaceUID: r_synapseWorkspace.properties.workspaceUID
      enableStreamingIngest: false
      optimizedAutoscale: {
        isEnabled: synapseADXPoolEnableAutoScale
        maximum: synapseADXPoolMaxSize
        minimum: synapseADXPoolMinSize
        version: 1
      }
    }

    resource r_adxDatabase 'databases' = {
      name: synapseADXDatabaseName
      kind: 'ReadWrite'
      location: resourceLocation
    }
  }
}

//Synapse Workspace Role Assignment as Blob Data Contributor Role in the Data Lake Storage Account
//https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-grant-workspace-managed-identity-permissions
resource r_dataLakeRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(r_synapseWorkspace.name, r_workspaceDataLakeAccount.name)
  scope: r_workspaceDataLakeAccount
  properties:{
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureRBACStorageBlobDataContributorRoleID)
    principalId: r_synapseWorkspace.identity.principalId
    principalType:'ServicePrincipal'
  }
}


output workspaceDataLakeAccountID string = r_workspaceDataLakeAccount.id
output workspaceDataLakeAccountName string = r_workspaceDataLakeAccount.name
output synapseWorkspaceID string = r_synapseWorkspace.id
output synapseWorkspaceName string = r_synapseWorkspace.name
output synapseSQLDedicatedEndpoint string = r_synapseWorkspace.properties.connectivityEndpoints.sql
output synapseSQLServerlessEndpoint string = r_synapseWorkspace.properties.connectivityEndpoints.sqlOnDemand
output synapseWorkspaceSparkID string = ctrlDeploySynapseSparkPool ? r_synapseWorkspace::r_sparkPool.id : ''
output synapseWorkspaceSparkName string = ctrlDeploySynapseSparkPool ? r_synapseWorkspace::r_sparkPool.name : ''
output synapseWorkspaceIdentityPrincipalID string = r_synapseWorkspace.identity.principalId
