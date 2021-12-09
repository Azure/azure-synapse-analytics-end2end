param privateEndpoitName string 
param resourceLocation string 
param privateLinkServiceId string
param groupID string
param subnetID string 
param deployDNSZoneGroup bool = true
param privateDNSZoneConfigs array

resource r_privateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: privateEndpoitName
  location:resourceLocation
  properties:{
    subnet:{
      id: subnetID
    }
    privateLinkServiceConnections:[
      {
        name:privateEndpoitName
        properties:{
          privateLinkServiceId: privateLinkServiceId
          groupIds:[
            groupID
          ]
        }
      }
    ]
  }

  resource r_vNetPrivateDNSZoneGroupSynapseSQL 'privateDnsZoneGroups' = if(deployDNSZoneGroup) {
    name: 'default'
    properties:{
      privateDnsZoneConfigs: privateDNSZoneConfigs
    }
  }
}
