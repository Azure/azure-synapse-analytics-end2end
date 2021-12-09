#
$ResourceGroup = "AzAnalyticsE2E-Deploy"
$workspaceName = "azsynapsewksgfz55"
$linkedServiceName = "azkeyvaultgfz55"
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
    #Connect-AzAccount -Subscription $SubscriptionId 
    #$identity = Get-AzUserAssignedIdentity -ResourceGroupName 'AzAnalyticsE2E-Deploy' -Name 'azanalyticse2e-deploy-uami'
    #Connect-AzAccount -Subscription $SubscriptionId -Identity -AccountId $identity.ClientId
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
########################################################################################################
#the following couple lines are optional if you are providing the ClientID directly
Connect-AzAccount -Subscription $SubscriptionId 
$identity = Get-AzUserAssignedIdentity -ResourceGroupName 'AzAnalyticsE2E-Deploy' -Name 'azanalyticse2e-deploy-uami'

#using -AccountId is only necessary when you have multiple managed identities linked to the Azure resource (i.e. Storage Account)
Connect-AzAccount -Subscription $SubscriptionId -Identity -AccountId $identity.ClientId

# ------------------------------------------
# get Bearer token for current user for Synapse Workspace API
$token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net").Token 
$headers = @{ Authorization = "Bearer $token" }
# ------------------------------------------

$uri = "https://$workspaceName.dev.azuresynapse.net" 
$uri += "/linkedservices/$linkedServiceName"
$uri += "?api-version=2019-06-01-preview"

$body = '{
    ""name"": ""$linkedServiceName"",
    ""properties"": {
        ""annotations"": [],
        ""type"": ""AzureKeyVault"",
        ""typeProperties"": {
            ""baseUrl"": ""https://$linkedServiceName.vault.azure.net/""
        }
    }
}'

$result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

Write-Host ($result | ConvertTo-Json)

