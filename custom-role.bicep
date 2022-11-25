@description('Role name')
param roleName string

@description('Role allowed action list')
param allowedActions array

@description('Role description')
param roleDescription string


resource role 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, roleName)
  properties: {
    assignableScopes: [
      resourceGroup().id
    ]
    description: roleDescription
    permissions: [
      {
        actions: allowedActions
        dataActions: [
        ]
        notActions: [
        ]
        notDataActions: [
        ]
      }
    ]
    roleName: roleName
  }
}

output roleId string = role.id
output roleName string = guid(subscription().id, roleName)
