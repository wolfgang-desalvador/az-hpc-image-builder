@description('Name of a Virtual Network to be created ad-hoc for the deployment')
param vnetName string

@description('Name of the subnet to be deployed in the Virtual Network')
param subnetName string

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet Prefix')
param subnetPrefix string = '10.0.0.0/24'

@description('Location where to deploy the resources')
param location string

module nsgModule 'nsg.bicep' = {
  name: 'nsg-deployment'
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          privateLinkServiceNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: nsgModule.outputs.nsgResourceId
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
