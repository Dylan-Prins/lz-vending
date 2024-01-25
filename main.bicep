targetScope = 'managementGroup'

param virtualNetworkLocation string = 'westeurope'
param existingSubscriptionId string
param roleAssignments array = []

param subscriptionAliasEnabled bool
param subscriptionName string = ''
param subscriptionBillingScope string = ''
param subscriptionManagementGroupId string
param subscriptionTags object
param subscriptionWorkload string

param virtualNetworkAddressSpace array
param virtualNetworkEnabled bool
param virtualNetworkDnsServers array = []
param virtualNetworkDdosPlanId string = ''
param virtualNetworkName string
param virtualNetworkPeeringEnabled bool
param virtualNetworkUseRemoteGateways bool = false

type tags = {
  owner: string
  environment: string
  costCenter: string
}

var virtualNetworkResourceGroupLockEnabled = true
var virtualNetworkResourceGroupName = 'connectivity'
var hubNetworkResourceId = '/subscriptions/1e95b10c-266b-4d4f-9be2-856a3bb1462e/resourceGroups/lucas-rsg/providers/Microsoft.Network/virtualNetworks/vmssagentspoolVNET'
var roleAssignmentEnabled = true
var subscriptionManagementGroupAssociationEnabled = true
var disableTelemetry = false
var resourceProviders = {}

module vending 'br/public:lz/sub-vending:1.5.1' = {
  name: 'vending'
  params: {
    disableTelemetry: disableTelemetry
    existingSubscriptionId: existingSubscriptionId
    hubNetworkResourceId: hubNetworkResourceId
    resourceProviders: resourceProviders
    roleAssignmentEnabled: roleAssignmentEnabled
    roleAssignments: roleAssignments
    subscriptionAliasEnabled: subscriptionAliasEnabled
    subscriptionAliasName: subscriptionName
    subscriptionBillingScope: subscriptionBillingScope
    subscriptionDisplayName: subscriptionName
    subscriptionManagementGroupAssociationEnabled: subscriptionManagementGroupAssociationEnabled
    subscriptionManagementGroupId: subscriptionManagementGroupId
    subscriptionTags: subscriptionTags
    subscriptionWorkload: subscriptionWorkload
    virtualNetworkAddressSpace: virtualNetworkAddressSpace
    virtualNetworkLocation: virtualNetworkLocation
    virtualNetworkEnabled: virtualNetworkEnabled
    virtualNetworkDnsServers: virtualNetworkDnsServers
    virtualNetworkDdosPlanId: virtualNetworkDdosPlanId
    virtualNetworkName: virtualNetworkName
    virtualNetworkPeeringEnabled: virtualNetworkPeeringEnabled
    virtualNetworkResourceGroupLockEnabled: virtualNetworkResourceGroupLockEnabled
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
    virtualNetworkUseRemoteGateways: virtualNetworkUseRemoteGateways
  }
}
