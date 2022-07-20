targetScope = 'subscription'

param location string
param computeResourceGroupName string

resource computeResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: computeResourceGroupName
  location: location
}

output name string = computeResourceGroup.name
