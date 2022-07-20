param computeVnetName string
param hubVnetId string

resource computeVnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: computeVnetName
}

resource computeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: 'computeToHubPeering'
  parent: computeVnet
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
