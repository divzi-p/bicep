targetScope = 'subscription'

param hubVnetName string = 'shadownet'
param hubResourceGroupName string = 'rg-hub-${deployment().name}'
param hubVnetCidr string = '10.11.0.0/16'
param testVmSubnetName string = 'testvm-subnet'
param testVmSubnetCidr string = '10.11.0.0/24'

param computeVnetName string = 'shadownet-compute'
param computeResourceGroupName string = 'rg-compute-${deployment().name}'
param computeVnetCidr string = '10.10.0.0/16'

param aksClusterName string = 'akstest'
// TODO: Lookup by name instead of using OID
// param aksClusterAdminGroupName string = '${aksClusterName}-admins'
param k8sVersion string = '1.20.9'

param aksSystemNodePoolName string = 'system'
param aksSystemNodePoolCount int = 3
param aksSystemNodePoolVmSku string = 'Standard_DS2_v2'
param aksSystemNodePoolSubnetName string = 'sn-aks-nodepool-${aksSystemNodePoolName}'
param aksSystemNodePoolSubnetCidr string = '10.10.16.0/20'

param aksOperationsNodePoolName string = 'operations'
param aksOperationsNodePoolCount int = 3
param aksOperationsNodePoolVmSku string = 'Standard_DS2_v2'
param aksOperationsNodePoolSubnetName string = 'sn-aks-nodepool-${aksOperationsNodePoolName}'
param aksOperationsNodePoolSubnetCidr string = '10.10.32.0/20'

param aksGeneralNodePoolName string = 'general'
param aksGeneralNodePoolCount int = 3
param aksGeneralNodePoolVmSku string = 'Standard_DS2_v2'
param aksGeneralNodePoolSubnetName string = 'sn-aks-nodepool-${aksGeneralNodePoolName}'
param aksGeneralNodePoolSubnetCidr string = '10.10.48.0/20'
param aksGeneralNodePoolAutoScale bool =false
param aksGeneralNodePoolMinCount int =3
param aksGeneralNodePoolMaxCount int =6

// test vm parameters
param testVMName string = 'vm-${deployment().name}'
param testVMSize string ='Standard_D4s_v3'
param vmAdminUsername string = 'testvmuser'
param vmAuthenticationType string ='sshPublicKey'
param vmUbuntuOSVersion string = '18.04-LTS'
param testVmSubnetNSG string = 'testVmSubnetNsg'
param testVmPasswordOrKey string

//acr parameters
param acrName string='acrperftest'
param acrAdminUserEnabled bool = true
param acrSku string= 'Basic'

module computeResourceGroup 'modules/compute-resource-group.bicep' = {
  name: '${deployment().name}-resourceGroup'
  scope: subscription()
  params: {
    location: deployment().location
    computeResourceGroupName: computeResourceGroupName
  }
}
module hubResourceGroup 'modules/compute-resource-group.bicep' = {
  name:  hubResourceGroupName 
  scope: subscription()
  params: {
    location: deployment().location
    computeResourceGroupName: hubResourceGroupName
  }
}
module computeVnet 'modules/vnet-compute.bicep' = {
  name: '${deployment().name}-computeVnet'
  scope: resourceGroup(computeResourceGroupName)
  dependsOn: [
    computeResourceGroup
  ]
  params: {
    location: deployment().location
    computeVnetName: computeVnetName
    computeVnetCidr: computeVnetCidr
    aksSystemNodePoolSubnetName: aksSystemNodePoolSubnetName
    aksSystemNodePoolSubnetCidr: aksSystemNodePoolSubnetCidr
    aksOperationsNodePoolSubnetName: aksOperationsNodePoolSubnetName
    aksOperationsNodePoolSubnetCidr: aksOperationsNodePoolSubnetCidr
    aksGeneralNodePoolSubnetName: aksGeneralNodePoolSubnetName
    aksGeneralNodePoolSubnetCidr: aksGeneralNodePoolSubnetCidr
  }
}

module hubVnet 'modules/vnet-hub.bicep' = {
  name: '${deployment().name}-computeVnet'
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [
    hubResourceGroup
  ]
  params: {
    location: deployment().location
    hubVnetName: hubVnetName
    hubVnetCidr: hubVnetCidr
    testVmSubnetName: testVmSubnetName
    testVmSubnetCidr: testVmSubnetCidr
    networkSecurityGroupName: testVmSubnetNSG
  }
}
module hubPeering 'modules/vnet-peering-hub.bicep' = {
  name: '${deployment().name}-hubPeering'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    hubVnetName: hubVnetName
    computeVnetId: computeVnet.outputs.computeVnetId
  }
}

module computePeering 'modules/vnet-peering-compute.bicep' = {
  name: '${deployment().name}-computePeering'
  scope: resourceGroup(computeResourceGroupName)
  params: {
    computeVnetName: computeVnetName
    hubVnetId: hubPeering.outputs.hubVnetId
  }
}



module aks 'modules/aks.bicep' = {
  name: '${deployment().name}-aks'
  scope: resourceGroup(computeResourceGroupName)
  params: {
    location: deployment().location
    computeVnetName: computeVnetName

    aksSystemNodePoolName: aksSystemNodePoolName
    aksSystemNodePoolCount: aksSystemNodePoolCount
    aksSystemNodePoolVmSku: aksSystemNodePoolVmSku
    aksSystemNodePoolSubnetName: computeVnet.outputs.aksSystemNodePoolSubnetName
    
    aksOperationsNodePoolName: aksOperationsNodePoolName
    aksOperationsNodePoolCount: aksOperationsNodePoolCount
    aksOperationsNodePoolVmSku: aksOperationsNodePoolVmSku
    aksOperationsNodePoolSubnetName: computeVnet.outputs.aksOperationsNodePoolSubnetName

    aksGeneralNodePoolName: aksGeneralNodePoolName
    aksGeneralNodePoolCount: aksGeneralNodePoolCount
    aksGeneralNodePoolVmSku: aksGeneralNodePoolVmSku
    aksGeneralNodePoolSubnetName: computeVnet.outputs.aksGeneralNodePoolSubnetName
    aksGeneralNodePoolAutoScale: aksGeneralNodePoolAutoScale
    aksGeneralNodePoolMinCount: aksGeneralNodePoolMinCount
    aksGeneralNodePoolMaxCount: aksGeneralNodePoolMaxCount
    aksClusterName: aksClusterName
    k8sVersion: k8sVersion
  }
}

module vmtest 'modules/vm-test.bicep' = {
  name: '${deployment().name}-vm'
  scope: resourceGroup(hubResourceGroupName)
  dependsOn: [
    hubVnet
  ]
  params: {
    location: deployment().location
    vmName: testVMName
    adminUsername: vmAdminUsername
    vmVnetName: hubVnetName
    authenticationType:vmAuthenticationType
    adminPasswordOrKey: testVmPasswordOrKey
    ubuntuOSVersion: vmUbuntuOSVersion
    vmSize: testVMSize
    subnetName:testVmSubnetName
  }
}

module acr 'modules/acr.bicep' = {
  name: '${deployment().name}-acr'
  scope: resourceGroup(computeResourceGroupName)
  dependsOn: [
    computeResourceGroup
  ]
  params: {
    location: deployment().location
    acrName: acrName
    acrAdminUserEnabled: acrAdminUserEnabled
    acrSku: acrSku
  }
}
