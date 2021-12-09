param dataShareAccountName string
param resourceLocation string
param purviewCatalogUri string

//Data Share Account
resource r_dataShareAccount 'Microsoft.DataShare/accounts@2020-09-01' = {
  name:dataShareAccountName
  location:resourceLocation
  identity:{
    type:'SystemAssigned'
  }
  tags:{
    catalogUri:purviewCatalogUri
  }
}

output dataShareAccountName string = r_dataShareAccount.name
output dataShareAccountID string = r_dataShareAccount.id
output dataShareAccountPrincipalID string = r_dataShareAccount.identity.principalId
