[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $SubscriptionName
)

Connect-AzAccount -Identity

$subscriptionId = Get-AzSubscription | Where-Object { $_.Name -eq $SubscriptionName } | Select-Object -ExpandProperty Id

if(-not $subscriptionId) {
    $DeploymentScriptOutputs['subscriptionId'] = ''
} else {
    $DeploymentScriptOutputs['subscriptionId'] = $subscriptionId
}