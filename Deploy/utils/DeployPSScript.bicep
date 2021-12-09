param deploymentDatetime string = utcNow()
param resourceLocation string = resourceGroup().location
var deploymentScriptUAMIName = toLower('${resourceGroup().name}-uami')

//User-Assignment Managed Identity used to execute deployment scripts
resource r_deploymentScriptUAMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: deploymentScriptUAMIName
  location: resourceLocation
}

//Synapse Deployment Script
var synapsePostDeploymentPSScript = 'aHR0cHM6Ly9jc2FkZW1vc3RvcmFnZS5ibG9iLmNvcmUud2luZG93cy5uZXQvcG9zdC1kZXBsb3ktc2NyaXB0cy9BcHByb3ZlUHJpdmF0ZUVuZHBvaW50U1AucHMx'
resource r_synapsePostDeployScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name:'DeployPSScript-${deploymentDatetime}'
  dependsOn: [
  ]
  location: resourceLocation
  kind:'AzurePowerShell'
  identity:{
    type:'UserAssigned'
    userAssignedIdentities: {
      '${r_deploymentScriptUAMI.id}': {}
    }
  }
  properties:{
    azPowerShellVersion:'6.2'
    cleanupPreference:'OnSuccess'
    retentionInterval: 'P1D'
    timeout:'PT30M'
    //arguments: '-DeploymentMode ${deploymentMode} -SubscriptionID ${subscription().subscriptionId} -WorkspaceName ${synapseWorkspaceName} -UAMIIdentityID ${r_deploymentScriptUAMI.properties.principalId} -KeyVaultName ${keyVaultName} -KeyVaultID ${r_keyVault.id} ${azMLSynapseLinkedServiceIdentityID} -DataLakeStorageAccountName ${dataLakeAccountName} -DataLakeStorageAccountID ${m_CoreServicesDeploy.outputs.dataLakeStorageAccountID}'
    primaryScriptUri: base64ToString(synapsePostDeploymentPSScript)
  }
}
