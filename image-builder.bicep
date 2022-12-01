@description('Series of commands to be executed for image customization. Refer to https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?tabs=json%2Cazure-powershell#properties-customize.')
param customize array

@description('Definition of distribution targets. Refer to https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?tabs=json%2Cazure-powershell#properties-distribute')
param distribute array

@description('Source image to be customized')
param sourceImage object

@description('VM Size to be used for image build process')
param vmSize string

@description('Image builder name')
param imageBuilderName string

@description('Image Builder identity name')
param imageBuilderIdentity string

@description('Name of the VNET where the builder should attach to')
param vnetId string

@description('Name of the target subnet')
param subnetName string

@description('User assigned identity object')
param userAssignedIdentityObject object = json(concat('{"', imageBuilderIdentity, '":{}}'))

@description('Location where to deploy the resources')
param location string = resourceGroup().location

resource imageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: imageBuilderName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentityObject
  }
  properties: {
    buildTimeoutInMinutes: 120
    customize: customize
    distribute: distribute
    source: sourceImage
    validate: {}
    vmProfile: {
      vmSize: vmSize
      vnetConfig: {
        subnetId: concat(vnetId, '/subnets/', subnetName)
      }
    }
  }
}
