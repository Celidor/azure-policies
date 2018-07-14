Function New-AllowedLocationsPolicy{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$True, HelpMessage='Allowed locations in format "[,northeurope,westeurope,uksouth,ukwest]"')]
    [string]$AllowedLocations,
    [Parameter(Mandatory=$True, HelpMessage='Name of Azure Policy in Microsoft built-in definition template, e.g. "Allowed Locations')]
    [string]$PolicyName,
    [Parameter(Mandatory=$True, HelpMessage='Azure Subscription ID, e.g. "11111111-1111-1111-1111-11111111111"')]
    [string]$Subscription
    )

    try {
      $policyAssignment = Get-AzureRmPolicyAssignment -Name $policyName -scope "/subscriptions/$subscription" -ErrorAction Stop
      Write-Output "$policyName policy already assigned"

    } catch {
      $definition = Get-AzureRmPolicyDefinition | where {$_.properties.displayName -eq $policyName -and $_.properties.policyType -eq "BuiltIn"}

      try {
        New-AzureRMPolicyAssignment -Name $policyName `
          -Scope "/subscriptions/$subscription" `
          -PolicyDefinition $definition `
          -listofAllowedLocations [,northeurope,uksouth,ukwest,westeurope,] `
          -Sku @{Name='A1';Tier='Standard'}

        $policyAssignment = Get-AzureRmPolicyAssignment -Name $policyName -scope "/subscriptions/$subscription"
        Write-Output $policyAssignment

        if ($policyAssignment.Name -eq $policyName) {
          Write-Output "$policyName policy assigned"

        } else {
          Write-Error -Message "$policyName policy not assigned correctly"

        }

      } catch {
          Write-Error -Message "$policyName policy could not be assigned"
      }
    }
}

Function New-ResourceTypesPolicy{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$True, HelpMessage='Name of Azure Policy in Microsoft built-in definition template, e.g. "Not Allowed Resource Types')]
    [string]$PolicyName,
    [Parameter(Mandatory=$false, HelpMessage='File with list of parameter types, e.g. "NotAllowedResourctTypes.txt"')]
    [string]$File = "NotAllowedResourceTypes.txt",
    [Parameter(Mandatory=$True, HelpMessage='Azure Subscription ID, e.g. "11111111-1111-1111-1111-11111111111"')]
    [string]$subscription
    )

    try {
      $policyAssignment = Get-AzureRmPolicyAssignment -Name $policyName -scope "/subscriptions/$subscription" -ErrorAction Stop
      Write-Output "$policyName policy already assigned"

    } catch {
      $definition = Get-AzureRmPolicyDefinition | where {$_.properties.displayName -eq $policyName -and $_.properties.policyType -eq "BuiltIn"}

      try {
        Write-Output "Importing $policyName from file $file"
        $listofResourceTypesNotAllowed = @(Get-Content $file)

      } catch {
        Write-Error "Error importing from file $file"
        Exit

      }

      try {
        New-AzureRMPolicyAssignment -Name $policyName `
          -Scope "/subscriptions/$subscription" `
          -PolicyDefinition $definition `
          -listofResourceTypesNotAllowed $listofResourceTypesNotAllowed `
          -Sku @{Name='A1';Tier='Standard'}

          $policyAssignment = Get-AzureRmPolicyAssignment -Name $policyName -scope "/subscriptions/$subscription"

        if ($policyAssignment.Name -eq $policyName) {
          Write-Output "$policyName policy assigned"

        } else {
          Write-Error -Message "$policyName policy not assigned correctly"

        }

      } catch {
          Write-Error -Message "$policyName policy could not be assigned"
      }
    }
}

Function Register-PolicyInsights{
[CmdletBinding()]
param (
  [Parameter(Mandatory=$True, HelpMessage='Azure Subscription ID, e.g. "11111111-1111-1111-1111-11111111111"')]
  [string]$subscription
  )

  $resourceProvider = Get-AzureRMResourceProvider | Where-Object {($_.ProviderNamespace -eq "Microsoft.PolicyInsights") -and `
    ($_.RegistrationState -eq "Registered")}

  # Register Policy Insights Resource Provider for the subscription
  if ($resourceProvider.ProviderNamespace -eq "Microsoft.PolicyInsights") {
  Write-Output "Policy Insights Resource Provider already registered"

  } else {
      try {
        Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.PolicyInsights"
        $resourceProviderCount = (Get-AzureRmResourceProvider -ProviderNamespace "Microsoft.PolicyInsights").count

        if ($resourceProviderCount -eq 3) {
          Write-Output "Policy Insights Resource Provider added to subscription"

        } else {
          Write-Error "Policy Insights Resource Proider not registered correctly"
        }

      } catch {
        Write-Error "Policy Insights Resource Provider could not be registered"

      }
  }
}

# Log in to Azure
./azurecredentials.ps1
# Gather information
Get-AzureRmSubscription | ForEach-Object {
  $subscription = $_.Id
  $subscriptionName = $_.Name
  Write-host "Set Azure Policies on $subscriptionName Subscription with ID $subscription ? (Default is Yes)" -ForegroundColor Yellow
  $Readhost = Read-Host " ( y / n ) "
  Switch ($ReadHost)
    {
      Y {Write-host "Yes, set Azure Policies"; $SetPolicies = $true}
      N {Write-Host "No, do not set Azure Policies"; $SetPolicies = $false}
      Default {Write-Host "Default, set Azure Policies"; $SetPolicies = $true}
    }

  if ($SetPolicies -eq $false) {
    Write-Output "Azure Policies not set on $subscriptionName Subscription with ID $subscription"

  } elseif ($setPolicies -eq $true) {

    Register-PolicyInsights -Subscription $subscription
    New-AllowedLocationsPolicy -Subscription $subscription -PolicyName "Allowed locations" -AllowedLocations "[,northeurope,westeurope,]"
    New-AllowedLocationsPolicy -Subscription $subscription -PolicyName "Allowed locations for resource groups" -AllowedLocations "[,northeurope,westeurope,]"
    New-ResourceTypesPolicy -Subscription $subscription -PolicyName "Not Allowed Resource Types"
    Write-Output "Azure Policies set on $subscriptionName Subscription with ID $subscription"

  }
}
