param keyVaultName string
param purviewIdentityPrincipalID string

resource r_keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}
resource r_keyVaultPurviewAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: 'add'
  parent: r_keyVault
  properties:{
    accessPolicies: [
      //Access Policy to allow Purview to Get and List Secrets
      //https://docs.microsoft.com/en-us/azure/purview/manage-credentials#grant-the-purview-managed-identity-access-to-your-azure-key-vault
      {
        objectId: purviewIdentityPrincipalID
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}
