targetScope = 'managementGroup'

param subscriptionAliasName string = ''
param subscriptionBillingScope string = ''
param subscriptionDisplayName string = ''
param subscriptionManagementGroupId string
param subscriptionTags object = {}
param roleAssignments array = []

param userAssignedIdentityName string = 'lz-vending-uai'
param deploymentScriptName string = 'lz-deploymentScript'

var subnetId = '/subscriptions/1e95b10c-266b-4d4f-9be2-856a3bb1462e/resourceGroups/rg-deployment-scripts/providers/Microsoft.Network/virtualNetworks/lz-vending-vnet/subnets/deploymentScripts'
var subscriptionId = '1e95b10c-266b-4d4f-9be2-856a3bb1462e'
var storageAccountId = '/subscriptions/1e95b10c-266b-4d4f-9be2-856a3bb1462e/resourceGroups/rg-deployment-scripts/providers/Microsoft.Storage/storageAccounts/lzvendingsa'
var resourceGroupName = 'rg-deployment-scripts'

type roleAssignment = {
  principalId: string
  roleDefinitionId: string
  scope: string
}[]

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: userAssignedIdentityName
}

module deploymentScript 'br/public:avm/res/resources/deployment-script:0.1.1' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'lz-vending-deploymentScript'
  params: {
    kind: 'AzurePowerShell'
    name: deploymentScriptName
    scriptContent: loadTextContent('./scripts/Get-SubscriptionId.ps1')
    enableTelemetry: false
    arguments: '-SubscriptionName "${subscriptionDisplayName}"'
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
  name: 'lz-vending-${subscriptionDisplayName}'
  params: {
    disableTelemetry: true
    resourceProviders: {}
    roleAssignmentEnabled: roleAssignments == [] ? false : true
    roleAssignments: roleAssignments
    subscriptionAliasEnabled: deploymentScript.outputs.outputs.subscriptionId == '' ? true : false
    existingSubscriptionId: deploymentScript.outputs.outputs.subscriptionId == '' ? '' : deploymentScript.outputs.outputs.subscriptionId
    subscriptionAliasName: deploymentScript.outputs.outputs.subscriptionId == '' ? subscriptionAliasName : ''
    subscriptionBillingScope: deploymentScript.outputs.outputs.subscriptionId == '' ? subscriptionBillingScope : ''
    subscriptionDisplayName: deploymentScript.outputs.outputs.subscriptionId == '' ? subscriptionDisplayName : ''
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: subscriptionManagementGroupId
    subscriptionTags: subscriptionTags
    subscriptionWorkload: 'Production'
    virtualNetworkEnabled: false
  }
}

output subscriptionId string = vending.outputs.subscriptionId
output subscriptionResourceId string = vending.outputs.subscriptionResourceId
