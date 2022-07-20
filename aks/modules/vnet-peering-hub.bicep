param hubVnetName string
param computeVnetId string

resource hubVnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: hubVnetName
}

resource hubToComputePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: 'hubToComputePeering'
  parent: hubVnet
  properties: {
    remoteVirtualNetwork: {
      id: computeVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

output hubVnetId string = hubVnet.id
