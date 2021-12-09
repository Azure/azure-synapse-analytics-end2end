$AADServicePrincipalAppId = "f025e7e3-16a2-44ea-9542-b2f509108ebe"
$SPPassword = "P@ssw0rd123!"
$TenantID = "12440d64-665a-435a-b445-97c5a9eccae3"
$SubscriptionId = "546dd5c1-8c8c-4ede-82f7-70a57c257266"

# Connect-AzureAD -TenantID $TenantID
# $ServicePrincipal = Get-AzureADServicePrincipal -Filter "DisplayName eq '$AADServicePrincipalName'"
# Write-Host $ServicePrincipal.AppId

$secpasswd = ConvertTo-SecureString -String $SPPassword -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AADServicePrincipalAppId,$secpasswd

Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Subscription $SubscriptionId -Credential $cred

$token = (Get-AzAccessToken -Resource "https://management.azure.com").Token 
$headers = @{ Authorization = "Bearer $token" }
# ------------------------------------------

#$uri = "https://management.azure.com/subscriptions/546dd5c1-8c8c-4ede-82f7-70a57c257266/resourceGroups/az-vnet-core-05/providers/Microsoft.Network/privateLinkServices/azkeyvaulttcjla/privateEndpointConnections?api-version=2019-09-01"
$uri = "https://management.azure.com/subscriptions/546dd5c1-8c8c-4ede-82f7-70a57c257266/resourceGroups/az-vnet-core-05/providers/Microsoft.KeyVault/vaults/azkeyvaulttcjla?api-version=2018-02-14"
$result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

Write-Host ($result | ConvertTo-Json)


$managedPrivateEndpointID = "/subscriptions/546dd5c1-8c8c-4ede-82f7-70a57c257266/resourceGroups/az-vnet-core-05/providers/Microsoft.KeyVault/vaults/azkeyvaulttcjla"
Get-AzPrivateEndpointConnection -PrivateLinkResourceId $managedPrivateEndpointID -ErrorAction Stop -Debug | select-object Id, ProvisioningState, PrivateLinkServiceConnectionState

#$access_token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
