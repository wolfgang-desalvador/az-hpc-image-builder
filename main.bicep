@description('Location where to deploy the resources')
param location string = resourceGroup().location

@description('VM Size to be used for the Azure Image Builder process')
param vmSize string = 'Standard_D4s_v5'

@description('Name of a Virtual Network to be created ad-hoc for the deployment')
param vnetName string

@description('Name of the subnet to be deployed in the Virtual Network')
param subnetName string

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet Prefix')
param subnetPrefix string = '10.0.0.0/24'


// Create the virtual network in the resource group with appropriate NSG
module vnet 'vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    vnetName: vnetName
    subnetName: subnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetPrefix: subnetPrefix
    location: location
  }
}

// Create a custom network role for the image builder
module imageBuilderNetworkRole 'image-builder-network-role.bicep' = {
  name: 'image-builder-network-role-deployment'
}

module imageBuilderCreatorRole 'image-builder-creator-role.bicep' = {
  name: 'image-builder-creator-role-deployment'
}

module imageBuilderIdentity 'managed-identity.bicep' = {
  name: 'image-builer-identity-deployment'
  params: {
    managedIdentityName: 'image-builder-identity'
  }
}

module imageBuilderNetworkRoleAssignment 'image-builder-role-assignment.bicep' = {
  dependsOn: [
    imageBuilderNetworkRole
    imageBuilderIdentity
  ]
  name: 'image-builder-network-role-assignment-deployment'
  params: {
    managedIdentityName: 'image-builder-identity'
    roleName: guid(subscription().id, 'Azure Image Builder Service Networking Role')
  }
}

module imageBuilderCreatorRoleAssignment 'image-builder-role-assignment.bicep' = {
  name: 'image-builder-creator-role-assignment-deployment'
  dependsOn: [
    imageBuilderCreatorRole
    imageBuilderIdentity
  ]
  params: {
    managedIdentityName: 'image-builder-identity'
    roleName: guid(subscription().id, 'Azure Image Builder Service Image Creation Role')
  }
}

module imageBuilder 'image-builder.bicep' = {
  name: 'image-builder-deployment'
  dependsOn: [
    imageBuilderNetworkRoleAssignment
    imageBuilderCreatorRoleAssignment
  ]
  params: {
    imageBuilderName: 'image-builder'
    vnetId: vnet.outputs.vnetId
    subnetName: subnetName
    imageBuilderIdentity: imageBuilderIdentity.outputs.managedIdentityIds.id
    imageName: 'ubuntuTest'
  }
}
