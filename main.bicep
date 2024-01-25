targetScope = 'managementGroup'

param subscriptionAliasName string = ''
param subscriptionBillingScope string = ''
param subscriptionDisplayName string = ''
param subscriptionManagementGroupId string
param subscriptionTags object = {}
param roleAssignments array = []

type roleAssignment = {
  principalId: string
  roleDefinitionId: string
  scope: string
}[]

module uai 'br/public:identity/user-assigned-identity:1.0.2' = {
  scope: resourceGroup('', '')
  name: 'subscriptionFinder'
  params: {
    location: 'west-europe'
  }
}

@description('Reader Role assignment for subscription finder')
resource roleassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: 'roleassignment'
  properties: {
    principalId: uai.outputs.principalId
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
    principalType: 'ServicePrincipal'
  }
}

module script 'br/public:avm/res/resources/deployment-script:0.1.1' = {
  scope: resourceGroup('', '')
  name: 'script'
  params: {
    kind: 'AzurePowerShell'
    name: 'script'
    scriptContent: loadTextContent('./scripts/Get-SubscriptionId.ps1')
    enableTelemetry: false
    azPowerShellVersion: '11.2.0'
    location: 'westeurope'
    subnetResourceIds:[
      '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/subnet'
    ]
    managedIdentities: {
      userAssignedResourcesIds: [
        uai.outputs.id
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
