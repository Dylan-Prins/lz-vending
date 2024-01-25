function Get-SubscriptionId {
    <#
.SYNOPSIS
    Creates Subscriptions using a enrollment account to a EA account
.DESCRIPTION
    Creates a subscription under a given management group
    The script should really be updated, since new-azsubscription is going to be deprecated.
.EXAMPLE
     - task: AzurePowerShell@4
    displayName: 'Azure PowerShell script: Create subscription'
    inputs:
      azureSubscription: Spn-DevOps-CCC_EA_Subscr-Admin
      ScriptPath: 'EASubscriptionManagement/New-AzureSubscription.ps1'
      scriptArguments:
        -EnvironmentType '${{ parameters.EnvironmentType }}'`
        -SubscriptionName '${{ parameters.SubscriptionName }}'`
        -ManagementGroupId '${{ parameters.ManagementGroupId }}'`
      azurePowerShellVersion: 'LatestVersion'
      Should be used from a Azure Devops Yaml Pipeline.
.NOTES
    Should be used from a Azure Devops Yaml Pipeline.
#>

    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $SubscriptionName
    )

    Connect-AzAccount -Identity

    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.AccessToken
    }

    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.AccessToken
    }

    try {
        $restUri = "https://management.azure.com/subscriptions?api-version=2020-01-01"
        $response = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader

        if ($null -ne ($response.value | Where-Object { $_.displayName -eq $SubscriptionName })) {
            $subscriptionId = ($response.value | Where-Object { $_.displayName -eq $SubscriptionName }).id.split('/')[2]
        }
    } catch {
        $subscriptionId = Get-AzSubscription | Where-Object { $_.Name -eq $SubscriptionName } | Select-Object -ExpandProperty Id
    }
    return $subscriptionId
}