Function Remove-AzurePolicy{
[CmdletBinding()]
param (
  [Parameter(Mandatory=$True, HelpMessage='Name of Azure Policy in Microsoft built-in definition template, e.g. "Audit SQL DB Level Audit Setting"')]
  [string]$PolicyName,
  [Parameter(Mandatory=$True, HelpMessage='Azure Subscription ID, e.g. "11111111-1111-1111-1111-11111111111"')]
  [string]$subscription
  )
 
  try {
    $policyAssignment = Get-AzureRmPolicyAssignment -Name $policyName -Scope "/subscriptions/$subscription" -ErrorAction Stop 
    Write-Output "Removing $policyName policy"
  
    try {
      Remove-AzureRMPolicyAssignment -Name $policyName -Scope "/subscriptions/$subscription" -ErrorAction Stop
      Write-Output "Removed Policy Assignment for $policyName policy"
        
    } catch {
      Write-Error -Message "Error removing Policy Assignment for $policyName policy" 
    
    }
      
  } catch {
    Write-Output "Policy $policyName not found"

  }
  
}    

# Log in to Azure
./azurecredentials.ps1
# Gather information
Get-AzureRmSubscription | ForEach-Object {
  $subscription = $_.Id
  $subscriptionName = $_.Name

  Write-host "Remove Azure Policies on $subscriptionName Subscription with ID $subscription ? (Default is Yes)" -ForegroundColor Yellow 
  $Readhost = Read-Host " ( y / n ) " 

  Switch ($ReadHost) 
    { 
      Y {Write-host "Yes, remove Azure Policies"; $SetPolicies = $true} 
      N {Write-Host "No, do not remove Azure Policies"; $SetPolicies = $false} 
      Default {Write-Host "Default, remove Azure Policies"; $SetPolicies = $true} 
    }
  
  if ($SetPolicies -eq $false) {
    Write-Output "Azure Policies not removed on $subscriptionName Subscription with ID $subscription"
    
  } elseif ($setPolicies -eq $true) {

    Write-Output "Removing Azure Policies from $subscriptionName Subscription with ID $subscription"
    Remove-AzurePolicy -Subscription $subscription -PolicyName "Allowed locations"
    Remove-AzurePolicy -Subscription $subscription -PolicyName "Allowed locations for resource groups"
    Remove-AzurePolicy -Subscription $subscription -PolicyName "Not Allowed resource types"
    Write-Output "Azure Policies removed from $subscriptionName Subscription with ID $subscription"
  }
}