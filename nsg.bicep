
@description('Location where to deploy the resources')
param location string = resourceGroup().location

@description('Network security group name')
param nsgName string = 'AzureImageBuilderNSG'

@description('Azure Image Builder rule priority')
param priority int = 400


resource nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AzureImageBuilderNsgRule'
        properties: {
          access: 'Allow'
          description: 'Allow Image Builder Private Link Access to Proxy VM'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '60000-60001'
          direction: 'inbound'
          priority: priority
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

output nsgResourceId string = nsg.id
