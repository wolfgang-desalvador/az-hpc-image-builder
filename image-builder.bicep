@description('Image builder name')
param imageBuilderName string

@description('Name of the gallery to be created in the resource group.')
param destinationGalleryName string

@description('Name of the image to be saved in the resource group.')
param destinationImageName string

@description('Image Builder identity name')
param managedIdentityName string = '${imageBuilderName}-identity'

// Image Builder parameters
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

@description('VM Size to be used for the Azure Image Builder process')
param vmSize string = 'Standard_D8ds_v5'

@description('Location where to deploy the resources')
param location string = resourceGroup().location

// Virtual Network parameters
@description('Image Builder Virtual Network name')
param virtualNetworkName string = '${imageBuilderName}-vnet'

@description('Name of the target subnet')
param subnetName string = 'default'

// Get the Image Gallery
resource hpcComputeGallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: destinationGalleryName
}

// Get the Image
resource imageName 'Microsoft.Compute/galleries/images@2022-03-03' existing = {
  name: destinationImageName
  parent: hpcComputeGallery
}

// Get the VNET
resource vNet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: virtualNetworkName
}

// Get Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource imageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  dependsOn: [
    vNet
    managedIdentity
    imageName
  ]
  name: imageBuilderName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: json(concat('{"', managedIdentity.id, '":{}}'))
  }
  properties: {
    buildTimeoutInMinutes: 120
    customize: customize
    distribute: [ {
        type: 'SharedImage'
        galleryImageId: imageName.id
        replicationRegions: [
          location
        ]
        runOutputName: destinationImageName
      }
    ]
    source: sourceImage
    validate: {}
    vmProfile: {
      vmSize: vmSize
      vnetConfig: {
        subnetId: concat(vNet.id, '/subnets/', subnetName)
      }
    }
  }
}
