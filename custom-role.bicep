@description('Role name')
param roleName string

@description('Role allowed action list')
param allowedActions array

@description('Role description')
param roleDescription string

@description('Role name GUID.')
param roleNameGUID string = guid(subscription().subscriptionId, resourceGroup().id, roleName)

resource role 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleNameGUID
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
    roleName: concat(roleName, '-', roleNameGUID)
  }
}

output roleId string = role.id
output roleName string = roleNameGUID
