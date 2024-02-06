targetScope = 'managementGroup'

param subscriptionAliasName string = ''
param subscriptionBillingScope string = ''
param subscriptionDisplayName string = ''
param subscriptionManagementGroupId string
param subscriptionTags object = {}
param roleAssignments array = []

var subnetId = '/subscriptions/1e95b10c-266b-4d4f-9be2-856a3bb1462e/resourceGroups/dylan-rg/providers/Microsoft.Network/virtualNetworks/salzvending-vnet/subnets/deploymentScripts'
var subscriptionId = '1e95b10c-266b-4d4f-9be2-856a3bb1462e'
var storageAccountId = '/subscriptions/1e95b10c-266b-4d4f-9be2-856a3bb1462e/resourceGroups/dylan-rg/providers/Microsoft.Storage/storageAccounts/stsihdt252lp6um'
var resourceGroupName = 'dylan-rg'

type roleAssignment = {
  principalId: string
  roleDefinitionId: string
  scope: string
}[]

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'subscriptionFinder'
}

module script 'br/public:avm/res/resources/deployment-script:0.1.1' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'script'
  params: {
    kind: 'AzurePowerShell'
    name: 'script'
    scriptContent: loadTextContent('./scripts/Get-SubscriptionId.ps1')
    enableTelemetry: false
    arguments: '-SubscriptionName ${subscriptionAliasName}'
    azPowerShellVersion: '11.0'
    retentionInterval: 'P1D'
    location: 'westeurope'
    runOnce: true
    storageAccountResourceId: storageAccountId
    subnetResourceIds:[
      subnetId
    ]
    managedIdentities: {
      userAssignedResourcesIds: [
        uai.id
      ]
    }
  }
}

module vending 'br/public:lz/sub-vending:1.5.1' = {
  name: 'vending'
  params: {
    disableTelemetry: true
    resourceProviders: {}
    roleAssignmentEnabled: roleAssignments == [] ? false : true
    roleAssignments: roleAssignments
    subscriptionAliasEnabled: script.outputs.outputs.subscriptionId == '' ? true : false
    existingSubscriptionId: script.outputs.outputs.subscriptionId == '' ? '' : script.outputs.outputs.subscriptionId
    subscriptionAliasName: script.outputs.outputs.subscriptionId == '' ? subscriptionAliasName : ''
    subscriptionBillingScope: script.outputs.outputs.subscriptionId == '' ? subscriptionBillingScope : ''
    subscriptionDisplayName: script.outputs.outputs.subscriptionId == '' ? subscriptionDisplayName : ''
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: subscriptionManagementGroupId
    subscriptionTags: subscriptionTags
    subscriptionWorkload: 'Production'
    virtualNetworkEnabled: false
  }
}

output subscriptionId string = vending.outputs.subscriptionId
output subscriptionResourceId string = vending.outputs.subscriptionResourceId
