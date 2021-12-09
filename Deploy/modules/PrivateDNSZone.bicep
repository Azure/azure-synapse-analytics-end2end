param dnsZoneName string 
param vNetName string 
param vNetID string 

resource r_privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'

  resource r_privateDNSZoneLink 'virtualNetworkLinks' = {
    name: '${dnsZoneName}-${vNetName}'
    location: 'global'
    properties:{
      virtualNetwork:{
        id:vNetID
      }
      registrationEnabled:false
    }
  }
}

output dnsZoneID string = r_privateDNSZone.id
