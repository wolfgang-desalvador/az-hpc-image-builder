@description('Compute Image Gallery name')
param galleryName string

@description('Location for resources, defaults to standard RG location')
param location string

@description('Compute Image Gallery description')
param galleryDescription string

@description('Custom image name')
param imageName string

@description('Custom image description')
param imageDescription string

@description('Custom image offer')
param imageOffer string

@description('Custom image publisher')
param imagePublisher string

@description('Custom image SKU')
param imageSKU string

@description('Custom image generation')
param VMGen string


resource hpcComputeGallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: galleryName
  location: location
  properties: {
    description: galleryDescription
  }
}


resource hpcImage 'Microsoft.Compute/galleries/images@2022-03-03' = {
  name: imageName
  location: location
  parent: hpcComputeGallery
  properties: {
    description: imageDescription
    hyperVGeneration: VMGen
    identifier: {
      offer: imageOffer
      publisher: imagePublisher
      sku: imageSKU
    }
    osState: 'Generalized'
    osType: 'Linux'
  }
}
