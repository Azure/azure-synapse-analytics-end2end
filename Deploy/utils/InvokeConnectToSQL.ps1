$AADServicePrincipalAppId = "f025e7e3-16a2-44ea-9542-b2f509108ebe"
$SPPassword = "P@ssw0rd123!"
$TenantID = "12440d64-665a-435a-b445-97c5a9eccae3"
$SubscriptionId = "546dd5c1-8c8c-4ede-82f7-70a57c257266"
$sqlServerlessEndpoint = "azsynapsewksskgip-ondemand.sql.azuresynapse.net"

If(-not(Get-InstalledModule SqlServer -ErrorAction silentlycontinue)) {
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module SqlServer -Confirm:$False -Force
}

# Connect-AzureAD -TenantID $TenantID
# $ServicePrincipal = Get-AzureADServicePrincipal -Filter "DisplayName eq '$AADServicePrincipalName'"
# Write-Host $ServicePrincipal.AppId

$secpasswd = ConvertTo-SecureString -String $SPPassword -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AADServicePrincipalAppId,$secpasswd

Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Subscription $SubscriptionId -Credential $cred

$access_token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token

$sql = "create login [azpurviewskgip] from external provider"
#$sql = "select suser_sname() as UserName"
$result = Invoke-Sqlcmd -ServerInstance $sqlServerlessEndpoint -query $sql -AccessToken $access_token -Database master
Write-Host "SQL command successful."
Write-Host ($result | ConvertTo-Json)
