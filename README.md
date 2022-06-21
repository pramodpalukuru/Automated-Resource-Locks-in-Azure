# Automated-Resource-Locks-in-Azure
This repository holds the script created and used for Automating the creation and updating process of  Resource Locks in Azure

SYNOPSIS
    
Connects to Azure and Locks the Resource Groups which do not have the 'Auto-DND-Lock' Lock applied on them.
    
DESCRIPTION
    
This Runbook connects to the All Subscriptions in the Azure environment on a defined schedule using the Azure Run As Account (Service Principal) or user account, checks the 'Auto-DND-Lock' Lock status on each Resource Group and applies the 'Auto-DND-Lock' Lock on the ones which do not have it.
     
NOTES
    
Author        :    Pramod Palukuru

Created       :    10-05-2020

Last Updated  :    10-05-2020

Version       :    1.0

INPUTS
    
The Inputs collected by this script from the Parameters are as follows:
1. List of Subscription Names from the Automation Variable
2. Any Excluded Resource Group Names from the Automation Variable
