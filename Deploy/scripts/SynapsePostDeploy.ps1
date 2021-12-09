param(
  [string] $DeploymentMode,
  [string] $SubscriptionID,
  [string] $ResourceGroupName,
  [string] $ResourceGroupLocation,
  [string] $WorkspaceName,
  [string] $KeyVaultName,
  [string] $KeyVaultID,
  [string] $DataLakeStorageAccountName,
  [string] $DataLakeStorageAccountID,
  [string] $UAMIIdentityID,
  [bool] $CtrlDeployAI,
  [AllowEmptyString()]
  [Parameter(Mandatory=$false)]
  [string] $AzMLSynapseLinkedServiceIdentityID,
  [AllowEmptyString()]
  [Parameter(Mandatory=$false)]
  [string] $AzMLWorkspaceName,
  [AllowEmptyString()]
  [Parameter(Mandatory=$false)]
  [string] $TextAnalyticsAccountName,
  [AllowEmptyString()]
  [Parameter(Mandatory=$false)]
  [string] $TextAnalyticsEndpoint,
  [AllowEmptyString()]
  [Parameter(Mandatory=$false)]
  [string] $AnomalyDetectorAccountName,
  [AllowEmptyString()]
  [Parameter(Mandatory=$false)]
  [string] $AnomalyDetectorEndpoint
)


#------------------------------------------------------------------------------------------------------------
# FUNCTION DEFINITION
#------------------------------------------------------------------------------------------------------------

function Save-SynapseLinkedService{
  param (
    [string] $WorkspaceName,
    [string] $LinkedServiceName,
    [string] $LinkedServiceRequestBody
  )

  [string] $uri = "https://$WorkspaceName.dev.azuresynapse.net/linkedservices/$LinkedServiceName"
  $uri += "?api-version=2019-06-01-preview"

  Write-Host "Creating Linked Service [$LinkedServiceName]..."
  $retrycount = 1
  $completed = $false

  while (-not $completed) {
    try {
      Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $LinkedServiceRequestBody -ErrorAction Stop
      Write-Host "Linked service [$LinkedServiceName] created successfully."
      $completed = $true
    }
    catch {
      if ($retrycount -ge $retries) {
          Write-Host "Linked service [$LinkedServiceName] creation failed the maximum number of $retryCount times."
          Write-Warning $Error[0]
          throw
      } else {
          Write-Host "Linked service [$LinkedServiceName] creation failed $retryCount time(s). Retrying in $secondsDelay seconds."
          Write-Warning $Error[0]
          Start-Sleep $secondsDelay
          $retrycount++
      }
    }
  }
}

#------------------------------------------------------------------------------------------------------------
# MAIN SCRIPT BODY
#------------------------------------------------------------------------------------------------------------

$retries = 10
$secondsDelay = 30

#------------------------------------------------------------------------------------------------------------
# ASSIGN WORKSPACE ADMINISTRATOR TO USER-ASSIGNED MANAGED IDENTITY
#------------------------------------------------------------------------------------------------------------

$token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net").Token
$headers = @{ Authorization = "Bearer $token" }

$uri = "https://$WorkspaceName.dev.azuresynapse.net/rbac/roleAssignments?api-version=2020-02-01-preview"

#Assign Synapse Workspace Administrator Role to UAMI
$body = "{
  roleId: ""6e4bf58a-b8e1-4cc3-bbf9-d73143322b78"",
  principalId: ""$UAMIIdentityID""
}"

Write-Host "Assign Synapse Administrator Role to UAMI..."

Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

#------------------------------------------------------------------------------------------------------------
# ASSIGN SYNAPSE APACHE SPARK ADMINISTRATOR TO AZURE ML LINKED SERVICE MSI
#------------------------------------------------------------------------------------------------------------

if (-not ([string]::IsNullOrEmpty($AzMLSynapseLinkedServiceIdentityID))) {
  #Assign Synapse Apache Spark Administrator Role to Azure ML Linked Service Managed Identity
  # https://docs.microsoft.com/en-us/azure/machine-learning/how-to-link-synapse-ml-workspaces#link-workspaces-with-the-python-sdk

  $body = "{
    roleId: ""c3a6d2f1-a26f-4810-9b0f-591308d5cbf1"",
    principalId: ""$AzMLSynapseLinkedServiceIdentityID""
  }"

  Write-Host "Assign Synapse Apache Spark Administrator Role to Azure ML Linked Service Managed Identity..."
  Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $uri -Headers $headers -Body $body

  # From: https://docs.microsoft.com/en-us/azure/synapse-analytics/security/how-to-manage-synapse-rbac-role-assignments
  # Changes made to Synapse RBAC role assignments may take 2-5 minutes to take effect.
  # Retry logic required before calling further APIs
}

#------------------------------------------------------------------------------------------------------------
# CREATE AZURE KEY VAULT LINKED SERVICE
#------------------------------------------------------------------------------------------------------------

#Create AKV Linked Service. Linked Service name same as Key Vault's.

$body = "{
  name: ""$KeyVaultName"",
  properties: {
      annotations: [],
      type: ""AzureKeyVault"",
      typeProperties: {
          baseUrl: ""https://$KeyVaultName.vault.azure.net/""
      }
  }
}"

Save-SynapseLinkedService $WorkspaceName $KeyVaultName $body

#------------------------------------------------------------------------------------------------------------
# CREATE AZURE ML LINKED SERVICE
#------------------------------------------------------------------------------------------------------------
#-AzMLWorkspaceName paramater will be passed blank if AI workloadis not deployed.

if (-not ([string]::IsNullOrEmpty($AzMLWorkspaceName))) {
  $body = "{
    name: ""$AzMLWorkspaceName"",
    properties: {
      annotations: [],
      type: ""AzureMLService"",
      typeProperties: {
          subscriptionId: ""$SubscriptionID"",
          resourceGroupName: ""$ResourceGroupName"",
          mlWorkspaceName: ""$AzMLWorkspaceName"",
          authentication: ""MSI""
      },
      connectVia: {
          referenceName: ""AutoResolveIntegrationRuntime"",
          type: ""IntegrationRuntimeReference""
      }
    }
  }"

  Save-SynapseLinkedService $WorkspaceName $AzMLWorkspaceName $body
}

#------------------------------------------------------------------------------------------------------------
# CREATE COGNITIVE SERVICES (TEXT ANALYTICS AND ANOMALY DETECTOR) LINKED SERVICES
#------------------------------------------------------------------------------------------------------------
if ($CtrlDeployAI) {
  $cognitiveServiceNames = $TextAnalyticsAccountName, $AnomalyDetectorAccountName
  $cognitiveServiceEndpoints = $TextAnalyticsEndpoint, $AnomalyDetectorEndpoint
  $cognitiveServiceTypes = "TextAnalytics", "AnomalyDetector"

  for ($i = 0; $i -lt $cognitiveServiceNames.Length ; $i++ ) {
    $body = "{
      name: ""$($cognitiveServiceNames[$i])"",
      properties: {
          annotations: [],
          type: ""CognitiveService"",
          typeProperties: {
              subscriptionId: ""$SubscriptionID"",
              resourceGroup: ""$ResourceGroupName"",
              csName: ""$($cognitiveServiceNames[$i])"",
              csKind: ""$($cognitiveServiceTypes[$i])"",
              csLocation: ""$ResourceGroupLocation"",
              endPoint: ""$($cognitiveServiceEndpoints[$i])"",
              csKey: {
                  type: ""AzureKeyVaultSecret"",
                  store: {
                      referenceName: ""$KeyVaultName"",
                      type: ""LinkedServiceReference""
                  },
                  secretName: ""$($cognitiveServiceNames[$i])-Key""
              }
          },
          connectVia: {
              referenceName: ""AutoResolveIntegrationRuntime"",
              type: ""IntegrationRuntimeReference""
          }
      }
    }"
  
    Save-SynapseLinkedService $WorkspaceName $cognitiveServiceNames[$i] $body
  }
}


#------------------------------------------------------------------------------------------------------------
# CREATE MANAGED PRIVATE ENDPOINTS
#------------------------------------------------------------------------------------------------------------

[string[]] $managedPrivateEndpointNames = $KeyVaultName, $DataLakeStorageAccountName
[string[]] $managedPrivateEndpointIDs = $KeyVaultID, $DataLakeStorageAccountID
[string[]] $managedPrivateEndpointGroups = 'vault', 'dfs'

if ($DeploymentMode -eq "vNet") {
  for($i = 0; $i -le ($managedPrivateEndpointNames.Length - 1); $i += 1)
  {
    $managedPrivateEndpointName = $managedPrivateEndpointNames[$i]
    $managedPrivateEndpointID = $managedPrivateEndpointIDs[$i]
    $managedPrivateEndpointGroup = $managedPrivateEndpointGroups[$i] 

    $uri = "https://$WorkspaceName.dev.azuresynapse.net"
    $uri += "/managedVirtualNetworks/default/managedPrivateEndpoints/$managedPrivateEndpointName"
    $uri += "?api-version=2019-06-01-preview"

    $body = "{
        name: ""$managedPrivateEndpointName"",
        type: ""Microsoft.Synapse/workspaces/managedVirtualNetworks/managedPrivateEndpoints"",
        properties: {
          privateLinkResourceId: ""$managedPrivateEndpointID"",
          groupId: ""$managedPrivateEndpointGroup"",
          name: ""$managedPrivateEndpointName""
        }
    }"

    Write-Host "Create Managed Private Endpoint for $managedPrivateEndpointName..."
    $retrycount = 1
    $completed = $false
    
    while (-not $completed) {
      try {
        Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
        Write-Host "Managed private endpoint for $managedPrivateEndpointName created successfully."
        $completed = $true
      }
      catch {
        if ($retrycount -ge $retries) {
          Write-Host "Managed private endpoint for $managedPrivateEndpointName creation failed the maximum number of $retryCount times."
          throw
        } else {
          Write-Host "Managed private endpoint creation for $managedPrivateEndpointName failed $retryCount time(s). Retrying in $secondsDelay seconds."
          Start-Sleep $secondsDelay
          $retrycount++
        }
      }
    }
  }

  #30 second delay interval for private link provisioning state = Succeeded
  $secondsDelay = 30

  #Approve Private Endpoints
  for($i = 0; $i -le ($managedPrivateEndpointNames.Length - 1); $i += 1)
  {
    $retrycount = 1
    $completed = $false
    
    while (-not $completed) {
      try {
        $managedPrivateEndpointName = $managedPrivateEndpointNames[$i]
        $managedPrivateEndpointID = $managedPrivateEndpointIDs[$i]
        # Approve KeyVault Private Endpoint
        $privateEndpoints = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $managedPrivateEndpointID -ErrorAction Stop | where-object{$_.PrivateEndpoint.Id -match ($WorkspaceName + "." + $managedPrivateEndpointName)} | select-object Id, ProvisioningState, PrivateLinkServiceConnectionState
        
        foreach ($privateEndpoint in $privateEndpoints) {
          if ($privateEndpoint.ProvisioningState -eq "Succeeded") {
            if ($privateEndpoint.PrivateLinkServiceConnectionState.Status -eq "Pending") {
              Write-Host "Approving private endpoint for $managedPrivateEndpointName."
              Approve-AzPrivateEndpointConnection -ResourceId $privateEndpoint.Id -Description "Auto-Approved" -ErrorAction Stop    
              $completed = $true
            }
            elseif ($privateEndpoint.PrivateLinkServiceConnectionState.Status -eq "Approved") {
              $completed = $true
            }
          }
        }
        
        if(-not $completed) {
          throw "Private endpoint connection not yet provisioned."
        }
      }
      catch {
        if ($retrycount -ge $retries) {
          Write-Host "Private endpoint approval for $managedPrivateEndpointName has failed the maximum number of $retryCount times."
          throw
        } else {
          Write-Host "Private endpoint approval for $managedPrivateEndpointName has failed $retryCount time(s). Retrying in $secondsDelay seconds."
          Write-Warning $PSItem.ToString()
          Start-Sleep $secondsDelay
          $retrycount++
        }
      }
    }
  }
}
