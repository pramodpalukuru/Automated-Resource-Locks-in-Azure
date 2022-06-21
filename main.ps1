<#
.SYNOPSIS
    Connects to Azure and Locks the Resource Groups which do not have the 'Auto-DND-Lock' Lock applied on them.
    
.DESCRIPTION
    This Runbook connects to the All Subscriptions in the Azure environment on a defined schedule using the 
    Azure Run As Account (Service Principal) or user account, checks the 'Auto-DND-Lock' Lock status on each 
    Resource Group and applies the 'Auto-DND-Lock' Lock on the ones which do not have it.
     
.NOTES
    Author        :    Pramod Palukuru
    Created       :    10-05-2020
    Last Updated  :    10-05-2020
    Version       :    1.0

.INPUTS
    The Inputs collected by this script from the Parameters are as follows:
    1. List of Subscription Names from the Automation Variable
    2. Any Excluded Resource Group Names from the Automation Variable
#>

Param(
    [Parameter(Mandatory= $true)]  
    [string]$SubscriptionIdList = "sub1id-139318-1cxxx-x183d,sub2id-139318-1cxxx-x183d,sub3id-139318-1cxxx-x183d",

    [Parameter(Mandatory= $false)]  
    [string]$ExcludedRGNames = "Excldrg1,ExcldRG2"
)

   "Logging in to Azure..."
Connect-AzAccount
if ($SubscriptionIdList -eq "*") {
    $Subscriptions = (Get-AzSubscription).Id
}
else
{
    $Subscriptions = $SubscriptionList.split(',')
}
$ExcludedResourceGroups = $ExcludedRGNames.split(',')

foreach($Subscription in $Subscriptions)
{
    Select-AzSubscription -SubscriptionId $Subscription

    $ResourceGroups = (Get-AzResourceGroup -Location 'West Europe').ResourceGroupName
    foreach ($ResourceGroup in $ResourceGroups)
    {
        $LockName = "Auto-DND-Lock"
        if(($ResourceGroup -like "AzureBackupRG_*") -or ($ResourceGroup -eq "NetworkWatcherRG"))
        {
            Write-Output "Automated Locks are not in scope for the Resource Group $($ResourceGroup)."
        }
        elseif($ExcludedResourceGroups -contains $ResourceGroup)
        {
            Write-Output "Automated Locks are exempted for the Resource Group $($ResourceGroup)."
        }
        else
        {
            $RGLocks = Get-AzResourceLock -ResourceGroupName $ResourceGroup | Where-Object Name -EQ $LockName
            if (($RGLocks -eq "") -or ($null -eq $RGLocks))
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