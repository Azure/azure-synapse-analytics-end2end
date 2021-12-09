param(
  [string] $PurviewAccountName,
  [string] $ScanEndpoint,
  [string] $APIVersion,
  [string] $KeyVaultName,
  [string] $KeyVaultID,
  [string] $UAMIIdentityID,
  [string] $DataLakeAccountName,
  [string] $SynapseWorkspaceName
)

$retries = 10
$secondsDelay = 5

Connect-AzAccount -Subscription 546dd5c1-8c8c-4ede-82f7-70a57c257266

$token = (Get-AzAccessToken -Resource "https://purview.azure.net").Token
$headers = @{ Authorization = "Bearer $token" }

$PurviewAccountName= "azpurview3f554"
$PolicyId = ""
$uri = "https://$PurviewAccountName.purview.azure.com/policystore/metadataPolicies/`?api-version=$APIVersion"

$retrycount = 1
$completed = $false

Write-Host "List Metadata Policies..."
while (-not $completed) {
  try {
    #Retrieve Purview default metadata policy ID
    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    $PolicyId = $result.values.Id
    $uri = "https://$PurviewAccountName.purview.azure.com/policystore/metadataPolicies/$PolicyId`?api-version=$APIVersion"

    #Retrieve Metadata Policy details and add Deployment Script UAMI PrincipalID to Collection Administrator and Data Source Administrator Roles.
    $result = Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    foreach ($attributeRule in $result.properties.attributeRules) {
      if ($attributeRule.id -like "*collection-administrator*" -or $attributeRule.id -like "*data-source-administrator*") {
        if (-not ($attributeRule.dnfCondition[0][0].attributeValueIncludedIn -contains $UAMIIdentityID)) {
          $attributeRule.dnfCondition[0][0].attributeValueIncludedIn += $UAMIIdentityID  
        }
      } 
    }

    #Update Metadata Policy
    $body = ConvertTo-Json -InputObject $result -Depth 10
    Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
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





