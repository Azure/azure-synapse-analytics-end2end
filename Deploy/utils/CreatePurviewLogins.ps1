

#------------------------------------------------------------------------------------------------------------
# CONFIGURE SQL LOGIN AND PERMISSIONS REQUIRED FOR AZURE PURVIEW
#------------------------------------------------------------------------------------------------------------

#If(-not(Get-InstalledModule SqlServer -ErrorAction silentlycontinue)) {
#  Set-PSRepository PSGallery -InstallationPolicy Trusted
#  Install-Module SqlServer -Confirm:$False -Force
#}
#
##Configure SQL Serverless and Dedicated SQL Pool with access for Azure Purview.
#$sqlServerlessEndpoint = "$WorkspaceName-ondemand.sql.azuresynapse.net"
#$sqlDedicatedPoolEndpoint = "$WorkspaceName.sql.azuresynapse.net"
#
##Retrieve AccessToken for UAMI
#$access_token = (Get-AzAccessToken -ResourceUrl https://sql.azuresynapse.net).Token
#
##Create SQL Serverless Database
#$SQLServerlessDatabaseName = "SQLServerlessDB"
#$sql = "CREATE DATABASE $SQLServerlessDatabaseName
#go
#CREATE LOGIN [$PurviewAccountName] FROM EXTERNAL PROVIDER;
#ALTER SERVER ROLE sysadmin ADD MEMBER [$PurviewAccountName];"
#
#Write-Host $sql
#
##Create Login for Azure Purview and set it as sysadmin
##as per https://docs.microsoft.com/en-us/azure/purview/register-scan-synapse-workspace#setting-up-authentication-for-enumerating-serverless-sql-database-resources-under-a-synapse-workspace
#
#$retrycount = 1
#$retries = 2
#$secondsDelay = 30
#$completed = $false
#
#while (-not $completed) {
#  try {
#    $result = Invoke-Sqlcmd -ServerInstance $sqlServerlessEndpoint -Database master -AccessToken $access_token -query $sql
#    #$result = Invoke-Sqlcmd -ServerInstance $sqlServerlessEndpoint -Database master -UserName $SynapseSqlAdminUserName -Password $SynapseSqlAdminPassword -query $sql
#    Write-Host "SQL Serverless config successful."
#    Write-Host ($result | ConvertTo-Json)
#    $completed = $true
#  }
#  catch {
#    if ($retrycount -ge $retries) {
#        Write-Host "SQL Serverless config failed the maximum number of $retryCount times."
#        throw
#    } else {
#        Write-Host "SQL Serverless config $retryCount time(s). Retrying in $secondsDelay seconds."
#        Start-Sleep $secondsDelay
#        $retrycount++
#    }
#  }
#}