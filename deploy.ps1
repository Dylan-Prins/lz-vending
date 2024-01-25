[CmdletBinding()]
param (
  [Parameter()]
  [string]
  $ManagementGroupId = 'DNA',

  [Parameter()]
  [string]
  $Location = 'westeurope'
)

$allowedTypes = @(
  'Corporate'
  'Isolated'
  'OnlineConnected'
)

$inputObject = @{
  DeploymentName    = 'lz-vend-{0}' -f ( -join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
  Location          = $Location
  TemplateFile      = "./main.bicep"
  ManagementGroupId = $ManagementGroupId
}

Get-ChildItem "./Landingzones" -Recurse -File -Filter "*.json" | ForEach-Object {
  $type = $_.PSParentPath | Split-Path -Leaf
  $json = Get-Content $_.FullName -Raw | ConvertFrom-Json

  if ($type -notin $allowedTypes) {
    Write-Error "Type not found"
    return
  }

  [hashtable]$GlobalhardCodedParameters = @{
    virtualNetworkLocation                 = 'westeurope'
    virtualNetworkEnabled                  = $true
    virtualNetworkName                     = $json.virtualNetworkName
    subscriptionWorkload                   = $json.tags.environment -eq "production" ? "Production" : "DevTest"
    subscriptionAliasEnabled               = $json.subscriptionAliasEnabled
    subscriptionTags                       = $json.tags
    existingSubscriptionId                 = $json.subscriptionId
  }

  switch ($type) {
    Corporate {
      [hashtable]$hardCodedParameters = @{
        virtualNetworkPeeringEnabled  = $true
        virtualNetworkAddressSpace    = @("10.0.0.0/24")
        subscriptionManagementGroupId = "DNA"
      }
    }
    Isolated {
      [hashtable]$hardCodedParameters = @{
        virtualNetworkPeeringEnabled  = $false
        virtualNetworkAddressSpace    = ""
        subscriptionManagementGroupId = "Isolated"
      }
    }
    OnlineConnected {
      [hashtable]$hardCodedParameters = @{
        virtualNetworkPeeringEnabled  = $true
        virtualNetworkAddressSpace    = ""
        subscriptionManagementGroupId = "OnlineConnected"
      }
    }
  }

  [hashtable]$inputObject.TemplateParameterObject = $GlobalhardCodedParameters + $hardCodedParameters
  New-AzManagementGroupDeployment @inputObject
}