param imageBuilderName string
param imageBuilderIdentity string
param vnetId string
param subnetName string
param userAssignedIdentity object = json(concat('{"', imageBuilderIdentity,'":{}}'))
param imageName string

resource imageBuilder 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: imageBuilderName
  location: resourceGroup().location
  identity: {
    type:'UserAssigned'
    userAssignedIdentities: userAssignedIdentity
  }
  properties:{
    buildTimeoutInMinutes: 180
    customize: [
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
    distribute: [{   
      type: 'ManagedImage'
      imageId: concat(resourceGroup().id, '/providers/Microsoft.Compute/images/', imageName)
      location: resourceGroup().location
      runOutputName: imageName
    artifactTags: {
        source: 'azVmImageBuilder'
        baseosimg: 'ubuntu2204'
    }
}
]
    source: {
      type: 'PlatformImage'
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts-gen2'
          version: 'latest'
  }
    validate: {}
    vmProfile: {
      vmSize: 'Standard_D8ds_v5'
      osDiskSizeGB: 120
      vnetConfig: {
        subnetId: concat(vnetId, '/subnets/', subnetName)
        }
      }
  }
}
