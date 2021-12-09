param(
  [string] $PurviewAccountName,
  [string] $SubscriptionId,
  [string] $ResourceGroupName,
  [string] $ScanEndpoint,
  [string] $APIVersion,
  [string] $KeyVaultName,
  [string] $KeyVaultID,
  [string] $UAMIIdentityID,
  [AllowEmptyString()]
  [Parameter(Mandatory=$false)]
  [string] $DataShareIdentityID,
  [string] $DataLakeAccountName,
  [string] $SynapseWorkspaceName
)

$retries = 10
$secondsDelay = 10

#------------------------------------------------------------------------------------------------------------
# ADD UAMIIdentityID TO COLLECTION ADMINISTRATOR ROLE
#------------------------------------------------------------------------------------------------------------

#Call Control Plane API to add UAMI as Collection Administrator

$token = (Get-AzAccessToken -Resource "https://management.azure.com").Token
$headers = @{ Authorization = "Bearer $token" }

$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Purview/accounts/$PurviewAccountName/addRootCollectionAdmin?api-version=2021-07-01"

$body = "{
  objectId: ""$UAMIIdentityID""
}"

$retrycount = 1
$completed = $false

while (-not $completed) {
  try {
    Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    $completed = $true
  }
  catch {
    if ($retrycount -ge $retries) {
        Write-Host "Metadata policy update failed the maximum number of $retryCount times."
        throw
    } else {
        Write-Host "Metadata policy update failed $retryCount time(s). Retrying in $secondsDelay seconds."
        Write-Warning $Error[0]
        Start-Sleep $secondsDelay
        $retrycount++
    }
  }
}

#------------------------------------------------------------------------------------------------------------
# ADD UAMIIdentityID TO DATA SOURCE ADMINISTRATOR ROLE
#------------------------------------------------------------------------------------------------------------

#Call Data Plane API to add UAMI as Data Source Administrator
$token = (Get-AzAccessToken -Resource "https://purview.azure.net").Token
$headers = @{ Authorization = "Bearer $token" }

$PolicyId = ""
$uri = "https://$PurviewAccountName.purview.azure.com/policystore/metadataPolicies/`?api-version=2021-07-01-preview"

$retrycount = 1
$completed = $false

while (-not $completed) {
  try {
    #Retrieve Purview default metadata policy ID
    Write-Host "List Metadata Policies..."
    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    $PolicyId = $result.values.Id

    Write-Host "Retrieve metadata policy (ID $PolicyId) details..."
    $uri = "https://$PurviewAccountName.purview.azure.com/policystore/metadataPolicies/$PolicyId`?api-version=2021-07-01-preview"

    #Retrieve Metadata Policy details 
    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop


    foreach ($attributeRule in $result.properties.attributeRules) {
      #Add Deployment Script UAMI PrincipalID to Data Source Administrator Role.
      if ($attributeRule.id -like "*data-source-administrator*") {
        if (-not ($attributeRule.dnfCondition[0][0].attributeValueIncludedIn -contains $UAMIIdentityID)) {
          $attributeRule.dnfCondition[0][0].attributeValueIncludedIn += $UAMIIdentityID  
        }
      #Add Data Share PrincipalID to Data Curator Role.
      } elseif ($attributeRule.id -like "*data-curator*" -and -not ([string]::IsNullOrEmpty($DataShareIdentityID))) {
        if (-not ($attributeRule.dnfCondition[0][0].attributeValueIncludedIn -contains $DataShareIdentityID)) {
          $attributeRule.dnfCondition[0][0].attributeValueIncludedIn += $DataShareIdentityID  
        }
      }
    }

    #Update Metadata Policy
    Write-Host "Update metadata policy (ID $PolicyId)..."
    $body = ConvertTo-Json -InputObject $result -Depth 10
    Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    $completed = $true
  }
  catch {
    if ($retrycount -ge $retries) {
        Write-Host "Metadata policy update failed the maximum number of $retryCount times."
        throw
    } else {
        Write-Host "Metadata policy update failed $retryCount time(s). Retrying in $secondsDelay seconds."
        Write-Warning $Error[0]
        Start-Sleep $secondsDelay
        $retrycount++
    }
  }
}

#------------------------------------------------------------------------------------------------------------
# CREATE KEY VAULT CONNECTION
#------------------------------------------------------------------------------------------------------------

$token = (Get-AzAccessToken -Resource "https://purview.azure.net").Token
$headers = @{ Authorization = "Bearer $token" }


$uri = $ScanEndpoint + "/azureKeyVaults/$KeyVaultName`?api-version=2018-12-01-preview" 
#Create KeyVault Connection
$body = "{
  ""name"": ""$KeyVaultName"",
  ""id"": ""$KeyVaultID"",
  ""properties"": {
      ""baseUrl"": ""https://$KeyVaultName.vault.azure.net/""
  }
}"

Write-Host "Creating Azure KeyVault connection..."

$retrycount = 1
$completed = $false

while (-not $completed) {
  try {
    $result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    Write-Host "KeyVault connection created successfully."
    $completed = $true
  }
  catch {
    if ($retrycount -ge $retries) {
        Write-Host "KeyVault connection failed the maximum number of $retryCount times."
        throw
    } else {
        Write-Host "KeyVault connection failed $retryCount time(s). Retrying in $secondsDelay seconds."
        Write-Warning $Error[0]
        Start-Sleep $secondsDelay
        $retrycount++
    }
  }
}

Write-Host "Registering Azure Data Lake data source..."

$uri = $ScanEndpoint + "/datasources/$DataLakeAccountName`?api-version=2018-12-01-preview"

#------------------------------------------------------------------------------------------------------------
# REGISTER DATA SOURCES
#------------------------------------------------------------------------------------------------------------

#Register Azure Data Lake data source
$body = "{
  ""kind"": ""AdlsGen2"",
  ""name"": ""$DataLakeAccountName"",
  ""properties"": {
      ""endpoint"": ""https://$DataLakeAccountName.dfs.core.windows.net/"",
      ""collection"": {
        ""type"": ""CollectionReference"",
        ""referenceName"": ""$PurviewAccountName""
      }
  }
}"

$retrycount = 1
$completed = $false

while (-not $completed) {
  try {
    $result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    Write-Host "Azure Data Lake source registered successfully."
    $completed = $true
  }
  catch {
    if ($retrycount -ge $retries) {
        Write-Host "Azure Data Lake source registration failed the maximum number of $retryCount times."
        throw
    } else {
        Write-Host "Azure Data Lake source registration failed $retryCount time(s). Retrying in $secondsDelay seconds."
        Write-Warning $Error[0]
        Start-Sleep $secondsDelay
        $retrycount++
    }
  }
}
#------------------------------------------------------------------------------------------------------------

#Register Synapse Workspace Data Source
$uri = $ScanEndpoint + "/datasources/$SynapseWorkspaceName\?api-version=2018-12-01-preview"

$SynapseSQLDedicatedEndpoint = $SynapseWorkspaceName + ".sql.azuresynapse.net"
$SynapseSQLServerlessEndpoint =  $SynapseWorkspaceName + "-ondemand.sql.azuresynapse.net"

$body = "{
  ""kind"": ""AzureSynapseWorkspace"",
  ""name"": ""$SynapseWorkspaceName"",
  ""properties"": {
      ""dedicatedSqlEndpoint"": ""$SynapseSQLDedicatedEndpoint"",
      ""serverlessSqlEndpoint"": ""$SynapseSQLServerlessEndpoint"",
      ""resourceName"": ""$SynapseWorkspaceName"",
      ""collection"": {
        ""type"": ""CollectionReference"",
        ""referenceName"": ""$PurviewAccountName""
      }
  }
}"

$retrycount = 1
$completed = $false

while (-not $completed) {
  try {
    $result = Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    Write-Host "Azure Synapse source registered successfully."
    $completed = $true
  }
  catch {
    if ($retrycount -ge $retries) {
        Write-Host "Azure Synapse source registration failed the maximum number of $retryCount times."
        throw
    } else {
        Write-Host "Azure Synapse source registration failed $retryCount time(s). Retrying in $secondsDelay seconds."
        Write-Warning $Error[0]
        Start-Sleep $secondsDelay
        $retrycount++
    }
  }
}
#------------------------------------------------------------------------------------------------------------
