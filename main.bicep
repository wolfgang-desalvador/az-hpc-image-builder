@description('Name of the image to be saved in the resource group.')
param destinationImageName string

@description('Description of the image to be saved in the resource group.')
param destinationImageDescription string

@description('Name of the gallery to be created in the resource group.')
param destinationGalleryName string

@description('Description of the gallery to be created in the resource group.')
param destinationGalleryDescription string

@description('Name of the image builder to be deployed')
param imageBuilderName string

@description('Series of commands to be executed for image customization. Refer to https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?tabs=json%2Cazure-powershell#properties-customize.')
param customize array = [
  {
    type: 'Shell'
    name: 'InstallUpgrades'
    inline: [
      'wget https://codeload.github.com/Azure/azhpc-images/zip/refs/heads/master -O azhpc-images-master.zip'
      'sudo apt-get install unzip'
      'unzip azhpc-images-master.zip'
      'sed -i "s%./install_nvidiagpudriver.sh%#./install_nvidiagpudriver.sh%g" azhpc-images-master/ubuntu/ubuntu-20.x/ubuntu-20.04-hpc/install.sh'
      'sed -i \'s%$UBUNTU_COMMON_DIR/install_nccl.sh%#$UBUNTU_COMMON_DIR/install_nccl.sh%g\' azhpc-images-master/ubuntu/ubuntu-20.x/ubuntu-20.04-hpc/install.sh'
      'sed -i \'s%rm /etc/%rm -f /etc/%g\' azhpc-images-master/ubuntu/common/install_monitoring_tools.sh'
      'cd azhpc-images-master/ubuntu/ubuntu-20.x/ubuntu-20.04-hpc/'
      'sudo ./install.sh'
      'cd -'
      'sudo rm -rf azhpc-images-master'
    ]
  }
]

@description('Source image to be customized')
param sourceImage object = {
  type: 'PlatformImage'
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-focal'
  sku: '20_04-lts-gen2'
  version: 'latest'
}

@description('HyperV Generation. Gen2 or Gen1. Refer to https://learn.microsoft.com/en-us/azure/virtual-machines/generation-2')
param VMGen string = 'V2'

@description('Name of the subnet to be deployed in the Virtual Network')
param subnetName string = 'default'

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet Prefix')
param subnetPrefix string = '10.0.0.0/24'

@description('VM Size to be used for the Azure Image Builder process')
param vmSize string = 'Standard_D8ds_v5'

@description('Location where to deploy the resources')
param location string = resourceGroup().location

// Create the virtual network in the resource group with appropriate NSG
module vnet 'vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    vnetName: '${imageBuilderName}-vnet'
    nsgName: '${imageBuilderName}-nsg'
    subnetName: subnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetPrefix: subnetPrefix
    location: location
  }
}

// Create a custom network role for the image builder
module imageBuilderNetworkRole 'custom-role.bicep' = {
  name: 'image-builder-network-role-deployment'
  params: {
    roleName: 'Azure Image Builder Service Networking Role'
    allowedActions: [
      'Microsoft.Network/virtualNetworks/read'
      'Microsoft.Network/virtualNetworks/subnets/join/action'
    ]
    roleDescription: 'Image Builder access to create resources for the image build'
  }
}

// Create a custom image creator role for the image builder
module imageBuilderCreatorRole 'custom-role.bicep' = {
  name: 'image-builder-creator-role-deployment'
  params: {
    roleName: 'Azure Image Builder Service Image Creation Role'
    allowedActions: [
      'Microsoft.Compute/galleries/read'
      'Microsoft.Compute/galleries/images/read'
      'Microsoft.Compute/galleries/images/versions/read'
      'Microsoft.Compute/galleries/images/versions/write'
      'Microsoft.Compute/images/write'
      'Microsoft.Compute/images/read'
      'Microsoft.Compute/images/delete'
    ]
    roleDescription: 'Image Builder access to create resources for the image build, you should delete or split out as appropriate'
  }
}

// Create an identity for the image builder
module imageBuilderIdentity 'managed-identity.bicep' = {
  name: 'image-builer-identity-deployment'
  params: {
    managedIdentityName: '${imageBuilderName}-identity'
    location: location
  }
}

// Assign the created roles to the identity
module imageBuilderNetworkRoleAssignment 'custom-role-assignment.bicep' = {
  dependsOn: [
    imageBuilderNetworkRole
    imageBuilderIdentity
  ]
  name: '${imageBuilderName}-network-role-assignment-deployment'
  params: {
    managedIdentityName: '${imageBuilderName}-identity'
    roleName: imageBuilderNetworkRole.outputs.roleName
  }
}

module imageBuilderCreatorRoleAssignment 'custom-role-assignment.bicep' = {
  name: '${imageBuilderName}-creator-role-assignment-deployment'
  dependsOn: [
    imageBuilderCreatorRole
    imageBuilderIdentity
  ]
  params: {
    managedIdentityName: '${imageBuilderName}-identity'
    roleName: imageBuilderCreatorRole.outputs.roleName
  }
}

// Create image gallery and image definition in gallery
module imageGallery 'compute-gallery.bicep' = {
  name: 'imageGallery'
  params: {
    imageName: destinationImageName
    imageDescription: destinationImageDescription
    imageOffer: sourceImage.offer
    imagePublisher: sourceImage.publisher
    imageSKU: sourceImage.sku
    galleryName: destinationGalleryName
    galleryDescription: destinationGalleryDescription
    location: location
    VMGen: VMGen
  }
}

// Create the image builder
module imageBuilder 'image-builder.bicep' = {
  name: '${imageBuilderName}-deployment'
  dependsOn: [
    imageBuilderNetworkRoleAssignment
    imageBuilderCreatorRoleAssignment
    imageGallery
  ]
  params: {
    imageBuilderName: imageBuilderName
    vnetId: vnet.outputs.vnetId
    subnetName: subnetName
    imageBuilderIdentity: imageBuilderIdentity.outputs.managedIdentityId
    sourceImage: sourceImage
    vmSize: vmSize
    customize: customize
    distribute: [ {
        type: 'SharedImage'
        galleryImageId: imageGallery.outputs.hpcComputeGalleryImageId
        replicationRegions: [
          location
        ]
        runOutputName: destinationImageName
      }
    ]
    location: location
  }
}
