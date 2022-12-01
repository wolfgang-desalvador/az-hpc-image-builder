@description('Name of Virtual Network to be created ad-hoc for the image-builder')
param vnetName string

@description('Name of the subnet to be created in the Virtual Network for image builder')
param subnetName string

@description('Name of the NSG to be created for the image builder subnet')
param nsgName string

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet Prefix')
param subnetPrefix string = '10.0.0.0/24'

@description('Location for resources, defaults to standard RG location')
param location string = resourceGroup().location

module nsgModule 'nsg.bicep' = {
  name: 'nsg-deployment'
  params: {
    location: location
    nsgName: nsgName
  }
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
