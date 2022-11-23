resource imageBuilderCreatorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'Azure Image Builder Service Image Creation Role')
  properties: {
    assignableScopes: [
      resourceGroup().id
    ]
    description: 'Image Builder access to create resources for the image build, you should delete or split out as appropriate'
    permissions: [
      {
        actions: [
        'Microsoft.Compute/galleries/read'
        'Microsoft.Compute/galleries/images/read'
        'Microsoft.Compute/galleries/images/versions/read'
        'Microsoft.Compute/galleries/images/versions/write'
        'Microsoft.Compute/images/write'
        'Microsoft.Compute/images/read'
        'Microsoft.Compute/images/delete'
        ]
        dataActions: [
        ]
        notActions: [
        ]
        notDataActions: [
        ]
      }
    ]
    roleName: 'Azure Image Builder Service Image Creation Role'
  }
}

output roleId string = imageBuilderCreatorRole.id
