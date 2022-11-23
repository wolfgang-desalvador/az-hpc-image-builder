param managedIdentityName string
param roleName string


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource role 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: roleName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, managedIdentity.id, role.id)
  properties: {
    roleDefinitionId: role.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
