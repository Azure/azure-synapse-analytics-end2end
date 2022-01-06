param resourceLocation string
param networkIsolationMode string
param existingVNetResourceGroupName string
param ctrlNewOrExistingVNet string
param vNetName string
param vNetSubnetName string
param vNetIPAddressPrefixes array
param vNetSubnetIPAddressPrefix string

param deploymentScriptUAMIName string
param keyVaultName string

var vNetID = ctrlNewOrExistingVNet == 'new' ? r_vNet.id : resourceId(subscription().subscriptionId, existingVNetResourceGroupName, 'Microsoft.Network/virtualNetworks',vNetName)
var subnetID = ctrlNewOrExistingVNet == 'new' ? r_subNet.id : '${vNetID}/subnets/${vNetSubnetName}'

//vNet created for network protected environments (networkIsolationMode == 'vNet')
resource r_vNet 'Microsoft.Network/virtualNetworks@2020-11-01' = if(networkIsolationMode == 'vNet' && ctrlNewOrExistingVNet == 'new'){
  name:vNetName
  location: resourceLocation
  properties:{
    addressSpace:{
      addressPrefixes: vNetIPAddressPrefixes
    }
  }
}

resource r_subNet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = if(networkIsolationMode == 'vNet' && ctrlNewOrExistingVNet == 'new') {
  name: vNetSubnetName
  parent: r_vNet
  properties: {
    addressPrefix: vNetSubnetIPAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies:'Enabled'
  }
}

//User-Assignment Managed Identity used to execute deployment scripts
resource r_deploymentScriptUAMI 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: deploymentScriptUAMIName
  location: resourceLocation
}

//Key Vault
resource r_keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: resourceLocation
  properties:{
    tenantId: subscription().tenantId
    enabledForDeployment:true
    enableSoftDelete:true
    sku:{
      name:'standard'
      family:'A'
    }
    networkAcls: {
      defaultAction: (networkIsolationMode == 'vNet')? 'Deny' : 'Allow'
      bypass:'AzureServices'
    }
    accessPolicies:[]
  }
}



output keyVaultID string = r_keyVault.id
output keyVaultName string = r_keyVault.name
output deploymentScriptUAMIID string = r_deploymentScriptUAMI.id
output deploymentScriptUAMIName string = r_deploymentScriptUAMI.name
output deploymentScriptUAMIPrincipalID string = r_deploymentScriptUAMI.properties.principalId
output vNetID string = vNetID
output subnetID string = subnetID
