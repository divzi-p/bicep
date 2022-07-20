param location string
param computeVnetName string
param computeVnetCidr string
param aksSystemNodePoolSubnetName string
param aksSystemNodePoolSubnetCidr string
param aksOperationsNodePoolSubnetName string
param aksOperationsNodePoolSubnetCidr string
param aksGeneralNodePoolSubnetName string
param aksGeneralNodePoolSubnetCidr string

resource computeVnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: computeVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        computeVnetCidr
      ]
    }
    subnets: [
      {
        name: aksSystemNodePoolSubnetName
        properties: {
          addressPrefix: aksSystemNodePoolSubnetCidr
        }
      }
      {
        name: aksOperationsNodePoolSubnetName
        properties: {
          addressPrefix: aksOperationsNodePoolSubnetCidr
        }
      }
      {
        name: aksGeneralNodePoolSubnetName
        properties: {
          addressPrefix: aksGeneralNodePoolSubnetCidr
        }
      }
    ]
  }
}

output computeVnetId string = computeVnet.id
output aksSystemNodePoolSubnetName string = computeVnet.properties.subnets[0].name
output aksOperationsNodePoolSubnetName string = computeVnet.properties.subnets[1].name
output aksGeneralNodePoolSubnetName string = computeVnet.properties.subnets[2].name
