
@description('Network security group name')
param nsgName string

@description('Location for resources, defaults to standard RG location')
param location string = resourceGroup().location

@description('Azure Image Builder rule priority')
param priority int = 400


resource nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: nsgName
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
