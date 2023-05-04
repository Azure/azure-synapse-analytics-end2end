//********************************************************
// Global Parameters
//********************************************************

@allowed([
  'default'
  'vNet'
])
@description('Network Isolation Mode')
param networkIsolationMode string = 'default'

@description('Resource Location')
param resourceLocation string = resourceGroup().location

@description('Unique Suffix')
param uniqueSuffix string = substring(uniqueString(resourceGroup().id),0,6)

//********************************************************
// Workload Deployment Control Parameters
//********************************************************

param ctrlDeployPurview bool = true     //Controls the deployment of Azure Purview
param ctrlDeployAI bool = true     //Controls the deployment of Azure ML and Cognitive Services
param ctrlDeployStreaming bool = true   //Controls the deployment of EventHubs and Stream Analytics
param ctrlDeployDataShare bool = true   //Controls the deployment of Azure Data Share
param ctrlDeployPrivateDNSZones bool = true //Controls the creation of private DNS zones for private links
param ctrlDeployOperationalDB bool = false  ////Controls the creation of operational Azure database data sources
param ctrlDeployCosmosDB bool = false //Controls the creation of CosmosDB if (ctrlDeployOperationalDBs == true)
param ctrlDeploySampleArtifacts bool = false //Controls the creation of sample artifcats (SQL Scripts, Notebooks, Linked Services, Datasets, Dataflows, Pipelines) based on chosen template.

@allowed([
  'OpenDatasets'
])
param sampleArtifactCollectionName string = 'OpenDatasets'

@allowed([
  'new'
  'existing'
])
param ctrlNewOrExistingVNet string = 'new'

@allowed([
  'eventhub'
  'iothub'
])
param ctrlStreamIngestionService string = 'eventhub'

param deploymentDatetime string = utcNow()
//********************************************************
// Resource Config Parameters
//********************************************************

//vNet Parameters

param existingVNetResourceGroupName string = resourceGroup().name

@description('Virtual Network Name')
param vNetName string = 'azvnet${uniqueSuffix}'

@description('Virtual Network IP Address Space')
param vNetIPAddressPrefixes array = [
  '10.1.0.0/16'
]

@description('Virtual Network Subnet Name')
param vNetSubnetName string = 'default'

@description('Virtual Network Subnet Name')
param vNetSubnetIPAddressPrefix string = '10.1.0.0/24'
//----------------------------------------------------------------------

//Data Lake Parameters
@description('Synapse Workspace Data Lake Storage Account Name')
param workspaceDataLakeAccountName string = 'azwksdatalake${uniqueSuffix}'

@description('Synapse Workspace Data Lake Storage Account Name')
param rawDataLakeAccountName string = 'azrawdatalake${uniqueSuffix}'

@description('Synapse Workspace Data Lake Storage Account Name')
param curatedDataLakeAccountName string = 'azcurateddatalake${uniqueSuffix}'

@description('Data Lake Raw Zone Container Name')
param dataLakeRawZoneName string = 'raw'

@description('Data Lake Trusted Zone Container Name')
param dataLakeTrustedZoneName string = 'trusted'

@description('Data Lake Curated Zone Container Name')
param dataLakeCuratedZoneName string = 'curated'

@description('Data Lake Transient Zone Container Name')
param dataLakeTransientZoneName string = 'transient'

@description('Data Lake Sandpit Zone Container Name')
param dataLakeSandpitZoneName string = 'sandpit'

@description('Synapse Default Container Name')
param synapseDefaultContainerName string = synapseWorkspaceName
//----------------------------------------------------------------------

//Synapse Workspace Parameters
@description('Synapse Workspace Name')
param synapseWorkspaceName string = 'azsynapsewks${uniqueSuffix}'

@description('SQL Admin User Name')
param synapseSqlAdminUserName string = 'azsynapseadmin'

@description('SQL Admin User Password')
param synapseSqlAdminPassword string

@description('Synapse Managed Resource Group Name')
param synapseManagedRGName string = '${synapseWorkspaceName}-mrg'

@description('Deploy SQL Pool')
param ctrlDeploySynapseSQLPool bool = false //Controls the creation of Synapse SQL Pool

@description('SQL Pool Name')
param synapseDedicatedSQLPoolName string = 'EnterpriseDW'

@description('SQL Pool SKU')
param synapseSQLPoolSKU string = 'DW100c'

@description('Deploy Spark Pool')
param ctrlDeploySynapseSparkPool bool = false //Controls the creation of Synapse Spark Pool

@description('Spark Pool Name')
param synapseSparkPoolName string = 'SparkPool'

@description('Spark Node Size')
param synapseSparkPoolNodeSize string = 'Small'

@description('Spark Min Node Count')
param synapseSparkPoolMinNodeCount int = 3

@description('Spark Max Node Count')
param synapseSparkPoolMaxNodeCount int = 3

@description('Deploy ADX Pool')
param ctrlDeploySynapseADXPool bool = false //Controls the creation of Synapse Spark Pool

@description('ADX Pool Name')
param synapseADXPoolName string = 'adxpool${uniqueSuffix}'

@description('ADX Database Name')
param synapseADXDatabaseName string = 'ADXDB'

@description('ADX Pool Enable Auto-Scale')
param synapseADXPoolEnableAutoScale bool = false

@description('ADX Pool Minimum Size')
param synapseADXPoolMinSize int = 2

@description('ADX Pool Maximum Size')
param synapseADXPoolMaxSize int = 2


//----------------------------------------------------------------------

//Synapse Private Link Hub Parameters
@description('Synapse Private Link Hub Name')
param synapsePrivateLinkHubName string = 'azsynapsehub${uniqueSuffix}'
//----------------------------------------------------------------------

//Purview Account Parameters
@description('Purview Account Name')
param purviewAccountName string = 'azpurview${uniqueSuffix}'

@description('Purview Managed Resource Group Name')
param purviewManagedRGName string = '${purviewAccountName}-mrg'

//----------------------------------------------------------------------

//Key Vault Parameters
@description('Data Lake Storage Account Name')
param keyVaultName string = 'azkeyvault${uniqueSuffix}'
//----------------------------------------------------------------------

//Azure Machine Learning Parameters
@description('Azure Machine Learning Workspace Name')
param azureMLWorkspaceName string = 'azmlwks${uniqueSuffix}'

@description('Azure Machine Learning Storage Account Name')
param azureMLStorageAccountName string = 'azmlstorage${uniqueSuffix}'

@description('Azure Machine Learning Application Insights Name')
param azureMLAppInsightsName string = 'azmlappinsights${uniqueSuffix}'

@description('Azure Machine Learning Container Registry Name')
param azureMLContainerRegistryName string = 'azmlcontainerreg${uniqueSuffix}'

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Azure Data Share Parameters
@description('Azure Data Share Name')
param dataShareAccountName string = 'azdatashare${uniqueSuffix}'
//----------------------------------------------------------------------

//Azure Cognitive Services Account Parameters
@description('Azure Cognitive Services Account Name')
param textAnalyticsAccountName string = 'aztextanalytics${uniqueSuffix}'
//----------------------------------------------------------------------

//Azure Anomaly Detector Account Parameters
@description('Azure Anomaly Detector Account Name')
param anomalyDetectorName string = 'azanomalydetector${uniqueSuffix}'
//----------------------------------------------------------------------

//Azure EventHub Namespace Parameters
@description('Azure EventHub Namespace Name')
param eventHubNamespaceName string = 'azeventhubns${uniqueSuffix}'

@description('Azure EventHub Name')
param eventHubName string = 'azeventhub${uniqueSuffix}'

@description('Azure EventHub SKU')
param eventHubSku string = 'Standard'

@description('Azure EventHub Partition Count')
param eventHubPartitionCount int = 1
//----------------------------------------------------------------------

//Azure IoT Hub Parameters
@description('Azure IoTHub Name')
param iotHubName string = 'aziothub${uniqueSuffix}'
@description('Azure IoTHub SKU')
param iotHubSku string = 'F1' //Free

//----------------------------------------------------------------------


//Stream Analytics Job Parameters
@description('Azure Stream Analytics Job Name')
param streamAnalyticsJobName string = 'azstreamjob${uniqueSuffix}'

@description('Azure Stream Analytics Job Name')
param streamAnalyticsJobSku string = 'Standard'


//CosmosDB account parameters
@description('CosmosDB Account Name')
param cosmosDBAccountName string = 'azcosmosdb${uniqueSuffix}'

@description('CosmosDB Database Name')
param cosmosDBDatabaseName string = 'OperationalDB'

//********************************************************
// Variables
//********************************************************

var deploymentScriptUAMIName = toLower('${resourceGroup().name}-uami')
//Data Lake zone containers
var rawDataLakeZoneContainerNames = [
  dataLakeTransientZoneName
  dataLakeRawZoneName
]

var curatedDataLakeZoneContainerNames = [
  dataLakeTrustedZoneName
  dataLakeCuratedZoneName
]

//********************************************************
// Platform Services 
//********************************************************

//Deploy required platform services
module m_PlatformServicesDeploy 'modules/PlatformServicesDeploy.bicep' = {
  name: 'PlatformServicesDeploy'
  params: {
    networkIsolationMode: networkIsolationMode
    deploymentScriptUAMIName: deploymentScriptUAMIName
    keyVaultName: keyVaultName 
    resourceLocation: resourceLocation
    ctrlNewOrExistingVNet: ctrlNewOrExistingVNet
    existingVNetResourceGroupName: existingVNetResourceGroupName
    vNetIPAddressPrefixes: vNetIPAddressPrefixes
    vNetSubnetIPAddressPrefix: vNetSubnetIPAddressPrefix
    vNetSubnetName: vNetSubnetName
    vNetName: vNetName
  }
}

//Deploy Core Services: Data Lake Account and Synapse Workspace.
module m_SynapseDeploy 'modules/SynapseDeploy.bicep' = {
  name: 'SynapseDeploy'
  dependsOn:[
    m_PurviewDeploy
  ]
  params: {
    networkIsolationMode: networkIsolationMode
    resourceLocation: resourceLocation
    ctrlDeploySynapseSQLPool: ctrlDeploySynapseSQLPool
    ctrlDeployPurview: ctrlDeployPurview
    ctrlDeploySynapseSparkPool: ctrlDeploySynapseSparkPool
    ctrlDeploySynapseADXPool: ctrlDeploySynapseADXPool
    workspaceDataLakeAccountName: workspaceDataLakeAccountName
    dataLakeSandpitZoneName: dataLakeSandpitZoneName
    synapseDefaultContainerName: synapseDefaultContainerName
    purviewAccountID: (ctrlDeployPurview == true)? m_PurviewDeploy.outputs.purviewAccountID : ''
    synapseDedicatedSQLPoolName: synapseDedicatedSQLPoolName
    synapseManagedRGName: synapseManagedRGName
    synapseSparkPoolMaxNodeCount: synapseSparkPoolMaxNodeCount
    synapseSparkPoolMinNodeCount: synapseSparkPoolMinNodeCount
    synapseSparkPoolName: synapseSparkPoolName
    synapseSparkPoolNodeSize: synapseSparkPoolNodeSize
    synapseADXPoolName: synapseADXPoolName
    synapseADXDatabaseName: synapseADXDatabaseName
    synapseADXPoolMinSize: synapseADXPoolMinSize
    synapseADXPoolMaxSize:synapseADXPoolMaxSize
    synapseADXPoolEnableAutoScale: synapseADXPoolEnableAutoScale
    synapseSqlAdminPassword: synapseSqlAdminPassword
    synapseSqlAdminUserName: synapseSqlAdminUserName
    synapseSQLPoolSKU: synapseSQLPoolSKU
    synapseWorkspaceName: synapseWorkspaceName
  }
}

//********************************************************
// PURVIEW DEPLOY
//********************************************************

//Deploy Purview Account
module m_PurviewDeploy 'modules/PurviewDeploy.bicep' = if (ctrlDeployPurview == true){
  name: 'PurviewDeploy'
  params: {
    purviewAccountName: purviewAccountName
    purviewManagedRGName: purviewManagedRGName
    resourceLocation: resourceLocation
  }
}


//*********************************************************************
// AI SERVICES DEPLOY: AZURE ML, ANOMALY DETECTOR AND TEXT ANALYTICS
//*********************************************************************

//Deploy AI Services: Azure Machine Learning Workspace (and dependent services) and Cognitive Services
module m_AIServicesDeploy 'modules/AIServicesDeploy.bicep' = if(ctrlDeployAI == true) {
  name: 'AIServicesDeploy'
  dependsOn: [
    m_PlatformServicesDeploy
  ]
  params: {
    anomalyDetectorAccountName: anomalyDetectorName
    azureMLAppInsightsName: azureMLAppInsightsName
    azureMLContainerRegistryName: azureMLContainerRegistryName
    azureMLStorageAccountName: azureMLStorageAccountName
    azureMLWorkspaceName: azureMLWorkspaceName
    textAnalyticsAccountName: textAnalyticsAccountName
    keyVaultID: m_PlatformServicesDeploy.outputs.keyVaultID
    resourceLocation: resourceLocation
    networkIsolationMode: networkIsolationMode
  }
}

//********************************************************
// DATA SHARE DEPLOY
//********************************************************

module m_DataShareDeploy 'modules/DataShareDeploy.bicep' = if(ctrlDeployDataShare == true){
  name: 'DataShareDeploy'
  params: {
    dataShareAccountName: dataShareAccountName
    resourceLocation: resourceLocation
    purviewCatalogUri: ctrlDeployPurview ? '${purviewAccountName}.catalog.purview.azure.com' : ''
  }
}

//********************************************************
// STREAMING SERVICES DEPLOY
//********************************************************

module m_StreamingServicesDeploy 'modules/StreamingServicesDeploy.bicep' = if(ctrlDeployStreaming == true) {
  name: 'StreamingServicesDeploy'
  params: {
    ctrlStreamIngestionService: ctrlStreamIngestionService
    eventHubNamespaceName: eventHubNamespaceName
    eventHubSku: eventHubSku
    iotHubName: iotHubName
    iotHubSku: iotHubSku
    resourceLocation: resourceLocation
    streamAnalyticsJobName: streamAnalyticsJobName
    streamAnalyticsJobSku: streamAnalyticsJobSku
    networkIsolationMode: networkIsolationMode
    subNetID: m_PlatformServicesDeploy.outputs.subnetID
  }
}

//********************************************************
// RAW AND CURATED DATA LAKES DEPLOY
//********************************************************

module m_DataLakeDeploy 'modules/DataLakeDeploy.bicep' = {
  name: 'DataLakeDeploy'
  dependsOn:[
    m_SynapseDeploy
    m_DataShareDeploy
    m_PurviewDeploy
    m_StreamingServicesDeploy
    m_AIServicesDeploy
  ]
  params: {
    curatedDataLakeAccountName: curatedDataLakeAccountName
    curatedDataLakeZoneContainerNames: curatedDataLakeZoneContainerNames
    rawDataLakeZoneContainerNames: rawDataLakeZoneContainerNames
    dataShareResourceID: ctrlDeployDataShare ? m_DataShareDeploy.outputs.dataShareAccountID : ''
    networkIsolationMode: networkIsolationMode
    purviewAccountResourceID: ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewAccountID : ''
    rawDataLakeAccountName: rawDataLakeAccountName
    resourceLocation: resourceLocation
    streamAnalyticsJobResourceID: ctrlDeployStreaming ? m_StreamingServicesDeploy.outputs.streamAnalyticsJobID : ''
    synapseWorkspaceResourceID: m_SynapseDeploy.outputs.synapseWorkspaceID
    azureMLWorkspaceResourceID: ctrlDeployAI? m_AIServicesDeploy.outputs.azureMLWorkspaceID : ''
    anomalyDetectorAccountResourceID: ctrlDeployAI? m_AIServicesDeploy.outputs.anomalyDetectorAccountID : ''
    languageServiceAccountResourceID: ctrlDeployAI? m_AIServicesDeploy.outputs.textAnalyticsAccountID : ''
    ctrlDeployStreaming: ctrlDeployStreaming
    ctrlStreamIngestionService: ctrlStreamIngestionService
    iotHubResourceID: ctrlDeployStreaming ? m_StreamingServicesDeploy.outputs.iotHubID : ''
  }
}


//********************************************************
// OPERATIONAL DATABASES DEPLOY
//********************************************************

module m_OperationalDatabasesDeploy 'modules/OperationalDBDeploy.bicep' = if(ctrlDeployOperationalDB) {
  name: 'OperationalDatabasesDeploy'
  dependsOn:[
    m_SynapseDeploy
  ]
  params: {
    networkIsolationMode: networkIsolationMode
    cosmosDBAccountName: cosmosDBAccountName
    cosmosDBDatabaseName: cosmosDBDatabaseName
    resourceLocation: resourceLocation
    ctrlDeployCosmosDB: ctrlDeployCosmosDB
    synapseWorkspaceID: m_SynapseDeploy.outputs.synapseWorkspaceID
  }
}

//********************************************************
// SERVICE CONNECTIONS DEPLOY
//********************************************************

module m_ServiceConnectionsDeploy 'modules/ServiceConnectionsDeploy.bicep' = {
  name: 'ServiceConnectionsDeploy'
  dependsOn:[
    m_PlatformServicesDeploy
    m_SynapseDeploy
    m_PurviewDeploy
    m_DataLakeDeploy
    m_AIServicesDeploy
    m_StreamingServicesDeploy
    m_OperationalDatabasesDeploy
  ]
  params: {
    ctrlDeployPurview: ctrlDeployPurview
    ctrlDeployAI:ctrlDeployAI
    ctrlDeployStreaming: ctrlDeployStreaming
    ctrlStreamIngestionService: ctrlStreamIngestionService
    ctrlSynapseDeploySparkPool: ctrlDeploySynapseSparkPool
    keyVaultName: m_PlatformServicesDeploy.outputs.keyVaultName
    purviewIdentityPrincipalID: ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewIdentityPrincipalID :''
    synapseWorkspaceIdentityPrincipalID: m_SynapseDeploy.outputs.synapseWorkspaceIdentityPrincipalID
    azureMLWorkspaceName: ctrlDeployAI ? m_AIServicesDeploy.outputs.azureMLWorkspaceName : azureMLWorkspaceName
    curatedDataLakeAccountName: m_DataLakeDeploy.outputs.curatedDataLakeStorageAccountName
    rawDataLakeAccountName: m_DataLakeDeploy.outputs.rawDataLakeStorageAccountName
    curatedDataLakeZoneContainerNames: curatedDataLakeZoneContainerNames
    rawDataLakeZoneContainerNames: rawDataLakeZoneContainerNames
    eventHubName: eventHubName
    eventHubNamespaceName: eventHubNamespaceName
    eventHubPartitionCount: eventHubPartitionCount
    rawDataLakeAccountID: m_DataLakeDeploy.outputs.rawDataLakeStorageAccountID
    anomalyDetectorAccountName:anomalyDetectorName
    resourceLocation: resourceLocation
    synapseWorkspaceID: m_SynapseDeploy.outputs.synapseWorkspaceID
    synapseWorkspaceName: m_SynapseDeploy.outputs.synapseWorkspaceName
    synapseSparkPoolID: ctrlDeploySynapseSparkPool ? m_SynapseDeploy.outputs.synapseWorkspaceSparkID : ''
    synapseSparkPoolName: ctrlDeploySynapseSparkPool ? m_SynapseDeploy.outputs.synapseWorkspaceSparkName : synapseSparkPoolName
    textAnalyticsAccountName:  textAnalyticsAccountName
    uamiPrincipalID: m_PlatformServicesDeploy.outputs.deploymentScriptUAMIPrincipalID
    cosmosDBAccountName: ctrlDeployCosmosDB ? m_OperationalDatabasesDeploy.outputs.cosmosDBAccountName : ''
    ctrlDeployCosmosDB: ctrlDeployCosmosDB
  }
}

//********************************************************
// RBAC Role Assignments
//********************************************************

module m_RBACRoleAssignment 'modules/AzureRBACDeploy.bicep' = {
  name: 'RBACRoleAssignmentDeploy'
  dependsOn:[
    m_ServiceConnectionsDeploy
    m_OperationalDatabasesDeploy
  ]
  params: {
    ctrlDeployDataShare: ctrlDeployDataShare
    dataShareAccountPrincipalID: ctrlDeployDataShare? m_DataShareDeploy.outputs.dataShareAccountPrincipalID : ''
    ctrlDeployStreaming: ctrlDeployStreaming
    streamAnalyticsIdentityPrincipalID: ctrlDeployStreaming? m_StreamingServicesDeploy.outputs.streamAnalyticsIdentityPrincipalID : ''
    ctrlDeployPurview: ctrlDeployPurview
    purviewIdentityPrincipalID: ctrlDeployPurview? m_PurviewDeploy.outputs.purviewIdentityPrincipalID : ''
    ctrlDeployAI: ctrlDeployAI
    azureMLWorkspaceName: ctrlDeployAI? m_AIServicesDeploy.outputs.azureMLWorkspaceName : ''
    azureMLSynapseLinkedServicePrincipalID: ctrlDeployAI ? m_ServiceConnectionsDeploy.outputs.azureMLSynapseLinkedServicePrincipalID : ''
    curatedDataLakeAccountName: curatedDataLakeAccountName
    rawDataLakeAccountName: rawDataLakeAccountName
    synapseWorkspaceName: m_SynapseDeploy.outputs.synapseWorkspaceName
    synapseWorkspaceIdentityPrincipalID: m_SynapseDeploy.outputs.synapseWorkspaceIdentityPrincipalID
    UAMIPrincipalID: m_PlatformServicesDeploy.outputs.deploymentScriptUAMIPrincipalID
    iotHubPrincipalID: ctrlDeployStreaming? m_StreamingServicesDeploy.outputs.iotHubPrincipalID : ''
    ctrlStreamingIngestionService: ctrlStreamIngestionService
    purviewAccountName: purviewAccountName
    ctrlDeployOperationalDB: ctrlDeployOperationalDB
    ctrlDeployCosmosDB: ctrlDeployCosmosDB
    cosmosDBAccountName: cosmosDBAccountName
    cosmosDBDatabaseName: cosmosDBDatabaseName
  }
}

module m_VirtualNetworkIntegration 'modules/VirtualNetworkIntegrationDeploy.bicep' = if(networkIsolationMode == 'vNet') {
  name: 'VirtualNetworkIntegration'
  dependsOn:[
    m_PlatformServicesDeploy
    m_SynapseDeploy
    m_PurviewDeploy
    m_AIServicesDeploy
    m_StreamingServicesDeploy
    m_DataLakeDeploy
  ]
  params: {
    ctrlDeployAI: ctrlDeployAI
    ctrlDeployPrivateDNSZones: ctrlDeployPrivateDNSZones
    ctrlDeployPurview: ctrlDeployPurview
    ctrlDeployStreaming: ctrlDeployStreaming
    ctrlStreamIngestionService: ctrlStreamIngestionService
    vNetName: vNetName
    subnetID: m_PlatformServicesDeploy.outputs.subnetID
    vNetID: m_PlatformServicesDeploy.outputs.vNetID
    anomalyDetectorAccountID: ctrlDeployAI ? m_AIServicesDeploy.outputs.anomalyDetectorAccountID : ''
    anomalyDetectorAccountName: ctrlDeployAI ? m_AIServicesDeploy.outputs.anomalyDetectorAccountName : ''
    azureMLContainerRegistryID: ctrlDeployAI ? m_AIServicesDeploy.outputs.containerRegistryID : ''
    azureMLContainerRegistryName: ctrlDeployAI ? m_AIServicesDeploy.outputs.containerRegistryName : ''
    azureMLStorageAccountID: ctrlDeployAI ? m_AIServicesDeploy.outputs.storageAccountID : ''
    azureMLStorageAccountName: ctrlDeployAI ? m_AIServicesDeploy.outputs.storageAccountName : ''
    azureMLWorkspaceID: ctrlDeployAI ? m_AIServicesDeploy.outputs.azureMLWorkspaceID : ''
    azureMLWorkspaceName: ctrlDeployAI ? m_AIServicesDeploy.outputs.azureMLWorkspaceName : ''
    curatedDataLakeAccountID: m_DataLakeDeploy.outputs.curatedDataLakeStorageAccountID
    curatedDataLakeAccountName: m_DataLakeDeploy.outputs.curatedDataLakeStorageAccountName
    eventHubNamespaceID: ctrlDeployStreaming ? m_StreamingServicesDeploy.outputs.eventHubNamespaceID : ''
    eventHubNamespaceName: ctrlDeployStreaming ? m_StreamingServicesDeploy.outputs.eventHubNamespaceName : ''
    iotHubID: ctrlDeployStreaming ? m_StreamingServicesDeploy.outputs.iotHubID : ''
    iotHubName: ctrlDeployStreaming ? m_StreamingServicesDeploy.outputs.iotHubName : ''
    keyVaultID: m_PlatformServicesDeploy.outputs.keyVaultID
    keyVaultName: m_PlatformServicesDeploy.outputs.keyVaultName
    purviewAccountID: ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewAccountID : ''
    purviewAccountName: ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewAccountName : ''
    purviewManagedEventHubNamespaceID: ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewManagedEventHubNamespaceID : ''
    purviewManagedStorageAccountID: ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewManagedStorageAccountID : ''
    rawDataLakeAccountID: m_DataLakeDeploy.outputs.rawDataLakeStorageAccountID
    rawDataLakeAccountName: m_DataLakeDeploy.outputs.rawDataLakeStorageAccountName
    resourceLocation: resourceLocation
    synapsePrivateLinkHubName: synapsePrivateLinkHubName
    synapseWorkspaceID: m_SynapseDeploy.outputs.synapseWorkspaceID
    synapseWorkspaceName: m_SynapseDeploy.outputs.synapseWorkspaceName
    textAnalyticsAccountID: ctrlDeployAI ? m_AIServicesDeploy.outputs.textAnalyticsAccountID : ''
    textAnalyticsAccountName: ctrlDeployAI ? m_AIServicesDeploy.outputs.textAnalyticsAccountName : ''
    workspaceDataLakeAccountID: m_SynapseDeploy.outputs.workspaceDataLakeAccountID
    workspaceDataLakeAccountName: m_SynapseDeploy.outputs.workspaceDataLakeAccountName
    cosmosDBAccountID: ctrlDeployOperationalDB && ctrlDeployCosmosDB ? m_OperationalDatabasesDeploy.outputs.cosmosDBAccountID : ''
    cosmosDBAccountName: ctrlDeployOperationalDB && ctrlDeployCosmosDB ? m_OperationalDatabasesDeploy.outputs.cosmosDBAccountName : ''
    ctrlDeployCosmosDB: ctrlDeployCosmosDB
  }
}

//********************************************************
// Post Deployment Scripts
//********************************************************

resource r_deploymentScriptUAMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: deploymentScriptUAMIName
}

//Synapse Deployment Script: script location encoded in Base64
var synapsePSScriptLocation = 'aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0F6dXJlL2F6dXJlLXN5bmFwc2UtYW5hbHl0aWNzLWVuZDJlbmQvbWFpbi9EZXBsb3kvc2NyaXB0cy9TeW5hcHNlUG9zdERlcGxveS5wczE='

var azMLSynapseLinkedServiceIdentityID = ctrlDeployAI ? '-AzMLSynapseLinkedServiceIdentityID ${m_ServiceConnectionsDeploy.outputs.azureMLSynapseLinkedServicePrincipalID}' : ''
var azMLWorkspaceName = ctrlDeployAI ? '-AzMLWorkspaceName ${azureMLWorkspaceName}' : ''
var azTextAnalyticsParams = ctrlDeployAI ? '-TextAnalyticsAccountID ${m_AIServicesDeploy.outputs.textAnalyticsAccountID} -TextAnalyticsAccountName ${textAnalyticsAccountName} -TextAnalyticsEndpoint ${m_AIServicesDeploy.outputs.textAnalyticsEndpoint}' : ''
var azCosmosDBParams = ctrlDeployCosmosDB ? '-CtrlDeployCosmosDB $${ctrlDeployCosmosDB} -CosmosDBAccountID ${m_OperationalDatabasesDeploy.outputs.cosmosDBAccountID} -CosmosDBAccountName ${m_OperationalDatabasesDeploy.outputs.cosmosDBAccountName} -CosmosDBDatabaseName ${m_OperationalDatabasesDeploy.outputs.cosmosDBDatabaseName}' : ''
var azAnomalyDetectorParams = ctrlDeployAI ? '-AnomalyDetectorAccountID ${m_AIServicesDeploy.outputs.anomalyDetectorAccountID} -AnomalyDetectorAccountName ${anomalyDetectorName} -AnomalyDetectorEndpoint ${m_AIServicesDeploy.outputs.anomalyDetectorEndpoint}' : ''
var datalakeAccountSynapseParams = '-WorkspaceDataLakeAccountName ${workspaceDataLakeAccountName} -WorkspaceDataLakeAccountID ${m_SynapseDeploy.outputs.workspaceDataLakeAccountID} -RawDataLakeAccountName ${rawDataLakeAccountName} -RawDataLakeAccountID ${m_DataLakeDeploy.outputs.rawDataLakeStorageAccountID} -CuratedDataLakeAccountName ${curatedDataLakeAccountName} -CuratedDataLakeAccountID ${m_DataLakeDeploy.outputs.curatedDataLakeStorageAccountID}'
var synapseWorkspaceParams = '-SynapseWorkspaceName ${synapseWorkspaceName} -SynapseWorkspaceID ${m_SynapseDeploy.outputs.synapseWorkspaceID}'
var sampleArtifactsParams = ctrlDeploySampleArtifacts ? '-CtrlDeploySampleArtifacts $True -SampleArtifactCollectioName ${sampleArtifactCollectionName}' : ''
var resourceNamesArray = [
  'azvnet=${vNetName}'
  'azsynapsewks=${synapseWorkspaceName}'
  'azwksdatalake=${workspaceDataLakeAccountName}'
  'azrawdatalake=${rawDataLakeAccountName}'
  'azcurateddatalake=${curatedDataLakeAccountName}'
  'azcosmosdbaccount=${cosmosDBAccountName}'
  'azcosmosdbname=${cosmosDBDatabaseName}'
  'azanomalydetector=${anomalyDetectorName}'
  'aztextanalytics=${textAnalyticsAccountName}'
  'azsynapsesqlpool=${synapseDedicatedSQLPoolName}'
  'azsynapsesparkpool=${synapseSparkPoolName}'
  'azsynapseadxpool=${synapseADXPoolName}'
  'azsynapseadxdb=${synapseADXDatabaseName}'
  'azsynapsehub=${synapsePrivateLinkHubName}'
  'azpurview=${purviewAccountName}'
  'azkeyvault=${keyVaultName}'
  'azmlwks=${azureMLWorkspaceName}'
  'azmlstorage=${azureMLStorageAccountName}'
  'azmlappinsights=${azureMLAppInsightsName}'
  'azmlcontainerreg=${azureMLContainerRegistryName}'
  'azdatashare=${dataShareAccountName}'
  'azeventhubns=${eventHubNamespaceName}'
  'azeventhub=${eventHubName}'
  'aziothub=${iotHubName}'
  'azstreamjob=${streamAnalyticsJobName}'
]

var resourceNamesCollectionParams = '-ResourceNamesCollectionString "${join(resourceNamesArray, '`n')}"'

//var synapseScriptArguments = '-NetworkIsolationMode ${networkIsolationMode} -ctrlDeployAI $${ctrlDeployAI} -SubscriptionID ${subscription().subscriptionId} -ResourceGroupName ${resourceGroup().name} -ResourceGroupLocation ${resourceGroup().location} -UAMIIdentityID ${m_PlatformServicesDeploy.outputs.deploymentScriptUAMIPrincipalID} -KeyVaultName ${keyVaultName} -KeyVaultID ${m_PlatformServicesDeploy.outputs.keyVaultID} ${synapseWorkspaceParams} ${azMLSynapseLinkedServiceIdentityID} ${datalakeAccountSynapseParams} ${azMLWorkspaceName} ${azTextAnalyticsParams} ${azAnomalyDetectorParams} ${azCosmosDBParams} ${sampleArtifactsParams}'

var synapseScriptArguments = join([
  '-NetworkIsolationMode ${networkIsolationMode}' 
  '-ctrlDeployAI $${ctrlDeployAI}'
  '-SubscriptionID ${subscription().subscriptionId}'
  '-ResourceGroupName ${resourceGroup().name}'
  '-ResourceGroupLocation ${resourceGroup().location}'
  '-UAMIIdentityID ${m_PlatformServicesDeploy.outputs.deploymentScriptUAMIPrincipalID}'
  '-KeyVaultName ${keyVaultName}'
  '-KeyVaultID ${m_PlatformServicesDeploy.outputs.keyVaultID}'
  '${synapseWorkspaceParams}'
  '${azMLSynapseLinkedServiceIdentityID}'
  '${datalakeAccountSynapseParams}'
  '${azMLWorkspaceName}'
  '${azTextAnalyticsParams}'
  '${azAnomalyDetectorParams}'
  '${azCosmosDBParams}'
  '${sampleArtifactsParams}'
//'${resourceNamesCollectionParams}'
], ' ')


//Purview Deployment Script: script location encoded in Base64
var purviewPSScriptLocation = 'aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0F6dXJlL2F6dXJlLXN5bmFwc2UtYW5hbHl0aWNzLWVuZDJlbmQvbWFpbi9EZXBsb3kvc2NyaXB0cy9QdXJ2aWV3UG9zdERlcGxveS5wczE='
var dataShareIdentityID = ctrlDeployDataShare ? '-DataShareIdentityID ${m_DataShareDeploy.outputs.dataShareAccountPrincipalID}' : ''
var datalakeAccountPurviewParams = '-WorkspaceDataLakeAccountName ${workspaceDataLakeAccountName} -RawDataLakeAccountName ${rawDataLakeAccountName} -CuratedDataLakeAccountName ${curatedDataLakeAccountName}'
var purviewScriptArguments = '-PurviewAccountID ${ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewAccountID : ''} -PurviewAccountName ${purviewAccountName} -SubscriptionID ${subscription().subscriptionId} -ResourceGroupName ${resourceGroup().name} -UAMIIdentityID ${m_PlatformServicesDeploy.outputs.deploymentScriptUAMIPrincipalID} -ScanEndpoint ${ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewScanEndpoint : ''} -APIVersion ${ctrlDeployPurview ? m_PurviewDeploy.outputs.purviewAPIVersion : ''} -SynapseWorkspaceName ${m_SynapseDeploy.outputs.synapseWorkspaceName} -SynapseWorkspaceIdentityID ${m_SynapseDeploy.outputs.synapseWorkspaceIdentityPrincipalID} -KeyVaultName ${keyVaultName} -KeyVaultID ${m_PlatformServicesDeploy.outputs.keyVaultID} ${datalakeAccountPurviewParams} ${dataShareIdentityID} -NetworkIsolationMode ${networkIsolationMode}'

//CleanUp Deployment Script: script location encoded in Base64
var cleanUpPSScriptLocation = 'aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0F6dXJlL2F6dXJlLXN5bmFwc2UtYW5hbHl0aWNzLWVuZDJlbmQvbWFpbi9EZXBsb3kvc2NyaXB0cy9DbGVhblVwUG9zdERlcGxveS5wczE='
var cleanUpScriptArguments = '-UAMIResourceID ${r_deploymentScriptUAMI.id}'

module m_PostDeploymentScripts 'modules/PostDeploymentScripts.bicep' = {
  name: 'PostDeploymentScript'
  dependsOn: [
    m_RBACRoleAssignment
    m_VirtualNetworkIntegration
  ]
  params: {
    cleanUpPSScriptLocation: cleanUpPSScriptLocation
    cleanUpScriptArguments: cleanUpScriptArguments
    ctrlDeployPurview: ctrlDeployPurview
    deploymentDatetime: deploymentDatetime
    deploymentScriptUAMIId: m_PlatformServicesDeploy.outputs.deploymentScriptUAMIID
    purviewPSScriptLocation: purviewPSScriptLocation
    purviewScriptArguments: purviewScriptArguments
    resourceLocation: resourceLocation
    synapsePSScriptLocation: synapsePSScriptLocation
    synapseScriptArguments: synapseScriptArguments
  }
}

//********************************************************
// Outputs
//********************************************************

