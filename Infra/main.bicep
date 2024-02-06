targetScope = 'managementGroup'

param storageAccountName string = 'salzvending01'
param virtualNetworkName string = 'salzvending-vnet'
param location string = 'westeurope'
param resourceGroupName string = 'dylan-rg'

var subscriptionId = '1e95b10c-266b-4d4f-9be2-856a3bb1462e'
var addressPrefix = '192.168.1.0/24'

module vnet 'br/public:avm/res/network/virtual-network:0.1.1' = {
  scope: resourceGroup(subscriptionId,resourceGroupName)
  name: virtualNetworkName
  params: {
    addressPrefixes: [addressPrefix]
    name: virtualNetworkName
    enableTelemetry: false
    subnets: [
      {
        name: 'default'
        addressPrefix: cidrSubnet(addressPrefix, 27, 0)
      }
      {
        name: 'deploymentScripts'
        addressPrefix: cidrSubnet(addressPrefix, 27, 1)
        delegations: [
          {
            name: 'deploymentscripts'
            properties: {
              serviceName: 'Microsoft.ContainerInstance/containerGroups'
            }
          }
        ]
      }
    ]
  }
}

module uai 'br/public:identity/user-assigned-identity:1.0.2' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'subscriptionFinder'
  params: {
    name: 'subscriptionFinder'
    location: 'westeurope'
  }
}

@description('Reader Role assignment for subscription finder')
resource roleassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscriptionId, resourceGroupName, 'Reader')
  properties: {
    principalId: uai.outputs.principalId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
    principalType: 'ServicePrincipal'
  }
}

module privateDnsZone 'br/public:network/private-dns-zone:1.0.1' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'privateDnsZone'
  params: {
    name: 'privatelink.file.${environment().suffixes.storage}'
    location: 'global'
  }
}

module sa 'br/public:storage/storage-account:3.0.1' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: storageAccountName
  params: {
    location: location
    kind: 'StorageV2'
    sku: 'Standard_LRS'
    storageRoleAssignments: [
      {
        principalId: uai.outputs.principalId
        roleDefinitionIdOrName: '/providers/Microsoft.Authorization/roleDefinitions/69566ab7-960f-475b-8e7c-b3118f30c6bd'
        principalType: 'ServicePrincipal'
      }
    ]
    privateEndpoints: [
      {
        name: 'privateEndpoint'
        groupId: 'file'
        subnetId: vnet.outputs.subnetResourceIds[0]
        privateDnsZoneId: privateDnsZone.outputs.id
      }
    ]
  }
}

output subnetId string = vnet.outputs.subnetResourceIds[1]
output storageAccountId string = sa.outputs.id
