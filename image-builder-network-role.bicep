resource imageBuilderNetworkRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'Azure Image Builder Service Networking Role')
  properties: {
    assignableScopes: [
      resourceGroup().id
    ]
    description: 'Image Builder access to create resources for the image build'
    permissions: [
      {
        actions: [
          'Microsoft.Network/virtualNetworks/read'
          'Microsoft.Network/virtualNetworks/subnets/join/action'
        ]
        dataActions: [
        ]
        notActions: [
        ]
        notDataActions: [
        ]
      }
    ]
    roleName: 'Azure Image Builder Service Networking Role'
  }
}

output roleId string = imageBuilderNetworkRole.id
