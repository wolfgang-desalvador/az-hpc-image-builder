@description('Manged identity name to be created')
param managedIdentityName string 

@description('Location for resources, defaults to standard RG location')
param location string = resourceGroup().location

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

output managedIdentityId string = managedIdentity.id
