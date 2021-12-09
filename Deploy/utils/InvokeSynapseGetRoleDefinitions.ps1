#
$workspaceName = "azsynapsewksklttj"
$SubscriptionId = "96bd7145-ad7f-445a-9763-862e32480bf1"

# ------------------------------------------
# these Az modules required
# https://docs.microsoft.com/powershell/azure/install-az-ps
Import-Module Az.Accounts 

########################################################################################################
#CONNECT TO AZURE

$Context = Get-AzContext

if ($Context -eq $null) {
    Write-Information "Need to login"
    Connect-AzAccount -Subscription $SubscriptionId 
    $identity = Get-AzUserAssignedIdentity -ResourceGroupName 'AzAnalyticsE2E-Deploy' -Name 'azanalyticse2e-deploy-uami'
    Connect-AzAccount -Subscription $SubscriptionId -Identity -AccountId $identity.ClientId
}
else
{
    Write-Host "Context exists"
    Write-Host "Current credential is $($Context.Account.Id)"
    if ($Context.Subscription.Id -ne $SubscriptionId) {
        $result = Select-AzSubscription -Subscription $SubscriptionId
        Write-Host "Current subscription is $($result.Subscription.Name)"
    }
    else {
        Write-Host "Current subscription is $($Context.Subscription.Name)"    
    }
}

# ------------------------------------------
# get Bearer token for current user for Synapse Workspace API
$token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net").Token 
$headers = @{ Authorization = "Bearer $token" }
# ------------------------------------------

$uri = "https://$workspaceName.dev.azuresynapse.net" 
$uri += "/rbac/roles?api-version=2020-02-01-preview"

Write-Host ($uri | ConvertTo-Json)

$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers

Write-Host ($result | ConvertTo-Json)