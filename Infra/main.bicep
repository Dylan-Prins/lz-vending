targetScope = 'managementGroup'

param storageAccountName string = 'lzvendingsa'
param virtualNetworkName string = 'lz-vending-vnet'
param location string = 'westeurope'
param resourceGroupName string = 'rg-deployment-scripts'

param userAssignedIdentityName string = 'lz-vending-uai'

var subscriptionId = '1e95b10c-266b-4d4f-9be2-856a3bb1462e'
var addressPrefix = '192.168.1.0/24'

module rg 'br/public:avm/res/resources/resource-group:0.4.0' = {
  scope: subscription(subscriptionId)
  name: 'lz-vending-infra-rg'
  params: {
    enableTelemetry: false
    name: resourceGroupName
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.1.1' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  dependsOn: [rg]
  name: 'lz-vending-infra-vnet'
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

module uai 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  dependsOn: [rg]
  name: 'lz-vending-infra-uai'
  params: {
    enableTelemetry: false
    name: userAssignedIdentityName
    location: 'westeurope'
  }
}

@description('Reader Role assignment for subscription finder')
resource roleassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscriptionId, resourceGroupName, 'Reader')
  properties: {
    principalId: uai.outputs.principalId
    roleDefinitionId: tenantResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    )
    principalType: 'ServicePrincipal'
  }
}

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.6.0' = {
  dependsOn: [rg]
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'lz-vending-infra-dns'
  params: {
    enableTelemetry: false
    name: 'privatelink.file.${environment().suffixes.storage}'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnet.outputs.resourceId

      }
    ]
  }
}

module sa 'br/public:avm/res/storage/storage-account:0.9.1' = {
  dependsOn: [rg]
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'lz-vending-infra-sa'
  params: {
    enableTelemetry: false
    location: location
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    name: storageAccountName
    publicNetworkAccess: 'Disabled'
    roleAssignments: [
      {
        principalId: uai.outputs.principalId
        roleDefinitionIdOrName: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
        principalType: 'ServicePrincipal'
      }
    ]
    privateEndpoints: [
      {
        service: 'file'
        subnetResourceId: vnet.outputs.subnetResourceIds[0]
        privateDnsZoneResourceIds: [privateDnsZone.outputs.resourceId]
        enableTelemetry: false
      }
    ]
  }
}

output subnetId string = vnet.outputs.subnetResourceIds[1]
output storageAccountId string = sa.outputs.resourceId
