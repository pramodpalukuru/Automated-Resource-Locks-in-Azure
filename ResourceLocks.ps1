<#

.SYNOPSIS
    Connects to Azure and Locks the Resource Groups which do not have the 'Auto-DND-Lock' Lock applied on them.
    
.DESCRIPTION
    This Runbook connects to the All LTI Managed Subscriptions in the ELKJOP Azure environment on a defined schedule
    using the Azure Run As Account (Service Principal), checks the 'Auto-DND-Lock' Lock status on each Resource Group
    and applies the 'Auto-DND-Lock' Lock on the ones which do not have it.
     
.NOTES
    Author        :    ELKJOP Automation Team
    Company       :    LTI
    Email         :    pramodreddy.p.v@lntinfotech.com
    Created       :    10-05-2020
    Last Updated  :    10-05-2020
    Version       :    1.0

.INPUTS
    The Inputs collected by this script from the Parameters are as follows:
    1. List of Subscription Names from the Automation Variable
    2. Any Excluded Resource Group Names from the Automation Variable
#>

$ConnectionName = "AzureRunAsConnection"

# Get the connection "AzureRunAsConnection"
$servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName

   "Logging in to Azure..."
Add-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

$SubscriptionList = Get-AutomationVariable -Name 'AllSubscriptionsinScope'
$Subscriptions = $SubscriptionList.split(',')

$ExcludedRGNames = Get-AutomationVariable -Name 'ExcludedRGNames'
$ExcludedResourceGroups = $ExcludedRGNames.split(',')

foreach($Subscription in $Subscriptions)
{
    Select-AzSubscription -SubscriptionName $Subscription

    $ResourceGroups = (Get-AzResourceGroup -Location 'West Europe').ResourceGroupName
    foreach ($ResourceGroup in $ResourceGroups)
    {
        $LockName = "Auto-DND-Lock"
        if(($ResourceGroup -like "AzureBackupRG_*") -or ($ResourceGroup -eq "NetworkWatcherRG"))
        {
            $NoOutput = Write-Output "Automated Locks are not in scope for the Resource Group $($ResourceGroup)."
        }
        elseif($ExcludedResourceGroups -contains $ResourceGroup)
        {
            Write-Output "Automated Locks are exempted for the Resource Group $($ResourceGroup)."
        }
        else
        {
            $RGLocks = Get-AzResourceLock -ResourceGroupName $ResourceGroup | where Name -EQ $LockName
            if (($RGLocks -eq "") -or ($RGLocks -eq $null))
            {
                #Write-Output "Auto-DND-Lock is missing on the Resource Group $($ResourceGroup)."
                New-AzResourceLock -LockName $LockName -LockLevel CanNotDelete -ResourceGroupName $ResourceGroup
                Write-Output "Auto-DND-Lock has been applied on the Resource Group $($ResourceGroup)."
            }
            else
            {
                Write-Output "Auto-DND-Lock is already in place on the Resource Group $($ResourceGroup)."
            }
        }
    }
}