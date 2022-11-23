param managedIdentityName string 

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: resourceGroup().location
}

output managedIdentityIds object = {
  principalId: managedIdentity.properties.principalId
  id: managedIdentity.id
}
