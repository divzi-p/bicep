param location string
param computeVnetName string

param aksClusterName string
param k8sVersion string


param aksSystemNodePoolName string
param aksSystemNodePoolCount int
param aksSystemNodePoolVmSku string
param aksSystemNodePoolSubnetName string

param aksOperationsNodePoolName string
param aksOperationsNodePoolCount int
param aksOperationsNodePoolVmSku string
param aksOperationsNodePoolSubnetName string

param aksGeneralNodePoolName string
param aksGeneralNodePoolCount int
param aksGeneralNodePoolVmSku string
param aksGeneralNodePoolSubnetName string
param aksGeneralNodePoolAutoScale bool
param aksGeneralNodePoolMinCount int
param aksGeneralNodePoolMaxCount int


resource computeVnet 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: computeVnetName
}

resource aksSystemNodePoolSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: aksSystemNodePoolSubnetName
  parent: computeVnet
}

resource aksOperationsNodePoolSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: aksOperationsNodePoolSubnetName
  parent: computeVnet
}

resource aksGeneralNodePoolSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: aksGeneralNodePoolSubnetName
  parent: computeVnet
}


resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: aksClusterName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: k8sVersion
    dnsPrefix: aksClusterName
    agentPoolProfiles: [
      {
        name: aksSystemNodePoolName
        count: aksSystemNodePoolCount
        type: 'VirtualMachineScaleSets'
        vmSize: aksSystemNodePoolVmSku
        mode: 'System'
        enableAutoScaling: true
        minCount: 3
        maxCount: 6
        vnetSubnetID: aksSystemNodePoolSubnet.id
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'  
        ]
      }
      {
        name: aksOperationsNodePoolName
        count: aksOperationsNodePoolCount
        type: 'VirtualMachineScaleSets'
        vmSize: aksOperationsNodePoolVmSku
        mode: 'User'
        enableAutoScaling: true
        minCount: 3
        maxCount: 6
        vnetSubnetID: aksOperationsNodePoolSubnet.id
        nodeTaints: [
          'Operations=true:NoSchedule'
        ]
      }
      {
        name: aksGeneralNodePoolName
        count: aksGeneralNodePoolCount
        type: 'VirtualMachineScaleSets'
        vmSize: aksGeneralNodePoolVmSku
        mode: 'User'
        enableAutoScaling: aksGeneralNodePoolAutoScale
        minCount: aksGeneralNodePoolAutoScale? aksGeneralNodePoolMinCount : null
        maxCount: aksGeneralNodePoolAutoScale? aksGeneralNodePoolMaxCount : null
        vnetSubnetID: aksGeneralNodePoolSubnet.id
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      // This won't work since we are using a subnet per nodepool. 
      // See: https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools#limitations-1
      // See: https://github.com/kubernetes/enhancements/tree/master/keps/sig-network/2450-Remove-knowledge-of-pod-cluster-CIDR-from-iptables-rules
      // networkPolicy: 'calico' 
      loadBalancerSku: 'standard'
    }
    
  }
  
}

output aksApiServerFqdn string = aksCluster.properties.fqdn
