# azure-policies
PowerShell script to configure Azure Security Policies for a subscription

Prerequisites:
* Git client
* PowerShell 5.1
* AzureRM PowerShell module 6.4.0

If running PowerShell scripts for the first time:
```
PS C:\> Set-ExecutionPolicy Unrestricted
Yes
```
Usage
* Duplicate and rename azurecredentials.ps1.example to azurecredentials.ps1
* Enter your credentials and save
* Start PowerShell as a standard user
```
PS C:\> .\New-SecurityPolicies.ps1
```
* To remove security polices from the subscription:
```
PS C:\> .\Remove-SecurityPolicies.ps1
```
