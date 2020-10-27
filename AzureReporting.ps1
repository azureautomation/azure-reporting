<#
.Synopsis
This function will gather basic information from an Azure subscription

.Description
This function will gather basic information from an Azure subscription
For example, cloud service, strage, vNet, VM information

.Parameter SubscriptionName
Provide Azure subscription name 

.Example
get-azuresubscriptiondetails -subscriptionname "Visual Studio Enterprise with MSDN" -credential admin@yourlab.com

#>
function get-azuresubscriptiondetails{

    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   HelpMessage = 'Please type one or more Azure Subscriotion as input and press ENTER')]
        [string]$subscriptionname,
        [Parameter(Mandatory=$True)]
        [string]$credential
             
    )

    Begin{

        $cred = Get-Credential -Message "Please enter the credential to login to Azure Subscription" -UserName $credential
        Write-Host -ForegroundColor Red "Cleaning the existing logged in account from PowerShell ....."
        Remove-AzureAccount -Name $credential -Force -WarningAction SilentlyContinue -WarningVariable wv1 -ErrorAction SilentlyContinue -ErrorVariable ev1
        Add-AzureAccount -Credential $cred -ErrorVariable ev2 -ErrorAction SilentlyContinue | Out-Null
        Add-AzureRmAccount -Credential $cred -ErrorVariable ev3 -ErrorAction SilentlyContinue | Out-Null
       
    }
    Process{
        $sub = (Get-AzureSubscription -Current -ErrorVariable ev4 -ErrorAction SilentlyContinue).SubscriptionName
        if($sub -eq $null){Write-Output "            " ; Write-host "No Subscription found or password is incorrect" -ForegroundColor Red;break}
        elseif($sub -eq $subscriptionname){Write-output "" ; Write-Host -ForegroundColor Green "Subscriptions $subscriptionname found, fetching information. Please wait .....";}
        else{Write-output ""; Write-Output ":: $subscriptionname :: is not the correct subscription, instead subscription :: $sub :: found";}

        Write-Output ""
        Write-Output " =====   Fetching Results from Azure Service Manager  ===== "

        $subscriptionname = $sub
        Get-AzureSubscription -SubscriptionName $subscriptionname
            
        ## Storage Information
        Write-Output ""; Write-Output "Storage Account Details"
        $sp = Write-Output "--------------------------------------------------";$sp
        $sta = Get-AzureStorageAccount -WarningVariable wv2 -WarningAction SilentlyContinue
        $sta | ?{$_.StorageAccountName -like "*"} |ft @{n="Name";e={$_.StorageAccountName}}, Location, 
                                                      @{n="Storage Type";e={$_.AccountType}}
        
        ## Virtual Machine Information
        Write-Output " "; Write-Output "Cloud Service Information"
        $sp; Get-AzureService | ?{$_.ServiceName -like "*"} | ft @{n="Cloud Service";e={$_.ServiceName}}, Location, 
                                                                 @{n="Date Created";e={$_.DateCreated}}
        
        $sp; Write-Output "Virtual Machines in the Subscription";
        Get-AzureVM | ?{$_.ServiceName -like "*"} | ft ServiceName, @{n="Server Name";e={$_.name}}, PowerState,
                                                                    @{n="VM Size";e={$_.InstanceSize}}, VirtualNetworkName,
                                                                    IPAddress, Status, DNSName -AutoSize
        ## vNet Information
        $sp; Write-Output "Virtual Network Details";
        Get-AzureVNetSite | ft @{n="vNet Name";e={$_.Name}}, Location, @{n="Address Space";e={$_.AddressSpacePrefixes}},
                            DNsServers, Subnets
            
        Write-Output ""
        Write-Output " =====   Fetching Results from Azure Resource Manager  ===== "
        
        ## Fecthcing VM information from RM
        $sp;  Get-AzureRmVm | ft ResourceGroupName, @{n="Server Name";e={$_.Name}}, Location

        Write-Output "Azure RM Storage Account Details"; Write-Output ""
        $sp ; Get-AzureRmStorageAccount |ft ResourceGroupName, StorageAccountName, Location, AccountType, CreationDate
        
        


            
            
    }
    End{}

}