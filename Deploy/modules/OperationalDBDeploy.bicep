param resourceLocation string 
param networkIsolationMode string
param synapseWorkspaceID string
param ctrlDeployCosmosDB bool = true

param cosmosDBAccountName string 
param cosmosDBDatabaseName string 

resource r_cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = if (ctrlDeployCosmosDB == true) {
  name: cosmosDBAccountName
  kind: 'GlobalDocumentDB'
  location: resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  properties:{
    databaseAccountOfferType:'Standard'
    locations:[
      {
        failoverPriority: 0
        locationName: resourceLocation
    }
    ]
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
        backupStorageRedundancy: 'Local'
      }
    }
    networkAclBypass: 'AzureServices' //Required to allow Synapse Link with SQL Serverless Pools.
    networkAclBypassResourceIds:[
      synapseWorkspaceID
    ]
    enableAnalyticalStorage: true
    publicNetworkAccess: networkIsolationMode == 'vNet' ? 'Disabled' : 'Enabled'
    analyticalStorageConfiguration:{
      schemaType: 'WellDefined'
    }
    capabilities:[
      {
        name: 'EnableServerless'
      }
    ]
  }

  resource r_cosmosDBDatabase 'sqlDatabases' = {
    name: cosmosDBDatabaseName
    properties: {
      resource: {
        id: cosmosDBDatabaseName
      }
    }
  }
}


output cosmosDBAccountID string = ctrlDeployCosmosDB ? r_cosmosDBAccount.id : ''
output cosmosDBAccountName string = ctrlDeployCosmosDB ? r_cosmosDBAccount.name : ''
output cosmosDBDatabaseName string = ctrlDeployCosmosDB ? r_cosmosDBAccount::r_cosmosDBDatabase.name : ''
output cosmosDBAccountEndpoint string = r_cosmosDBAccount.properties.documentEndpoint
