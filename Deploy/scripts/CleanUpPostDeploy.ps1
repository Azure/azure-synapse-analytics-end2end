param (
    [string] $UAMIResourceID
)

function Remove-DeploymentScriptUAMI{
    param (
      [string] $UAMIResourceID
    )
    
    $uri = "https://management.azure.com$UAMIResourceID`?api-version=2018-11-30"
    $token = (Get-AzAccessToken -Resource "https://management.azure.com").Token
    $headers = @{ Authorization = "Bearer $token" }
  
    $retrycount = 1
    $completed = $false
    $secondsDelay = 30
  
    while (-not $completed) {
      try {
        Invoke-RestMethod -Method Delete -ContentType "application/json" -Uri $uri -Headers $headers -ErrorAction Stop
        Write-Host "Deployment script user-assigned managed identity deleted successfully."
        $completed = $true
      }
      catch {
        if ($retrycount -ge $retries) {
            Write-Host "Delete user-assignment managed identity failed the maximum number of $retryCount times."
            Write-Warning $Error[0]
            throw
        } else {
            Write-Host "Delete user-assignment managed identity failed $retryCount time(s). Retrying in $secondsDelay seconds."
            Write-Warning $Error[0]
            Start-Sleep $secondsDelay
            $retrycount++
        }
      }
    }
  }

  Remove-DeploymentScriptUAMI($UAMIResourceID)