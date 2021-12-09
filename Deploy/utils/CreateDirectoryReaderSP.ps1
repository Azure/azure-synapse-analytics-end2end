#Param -- Default is AZOps
$ADServicePrincipal = "AADReaderSP"
$TenantID = "12440d64-665a-435a-b445-97c5a9eccae3"
$ADSPPassword = "P@ssw0rd123!"

if ((Get-InstalledModule -Name "Az.Resources" -ErrorAction SilentlyContinue) -eq $null) {
    Write-Host "Az.Resources Module does not exist" -ForegroundColor Yellow
    Install-Module -Name Az.Resources -Force
    Import-Module -Name Az.Resources
}
else {
    Import-Module -Name Az.Resources
}

#verify if AzureAD module is installed and running a minimum version, if not install with the latest version.
if ((Get-InstalledModule -Name "AzureAD" -MinimumVersion 2.0.2.130 ` -ErrorAction SilentlyContinue) -eq $null) {
    Write-Host "AzureAD Module does not exist" -ForegroundColor Yellow
    Install-Module -Name AzureAD -Force
    Import-Module -Name AzureAD
    Connect-AzureAD -TenantId $TenantID #sign in to Azure from Powershell, this will redirect you to a webbrowser for authentication, if required

}
else {
    Write-Host "AzureAD Module exists with minimum version" -ForegroundColor Yellow
    Import-Module -Name AzureAD
    Connect-AzureAD -TenantId $TenantID #sign in to Azure from Powershell, this will redirect you to a webbrowser for authentication, if required
}

#Verify Service Principal and if not pick a new one.
if (!(Get-AzureADServicePrincipal -Filter "DisplayName eq '$ADServicePrincipal'")) { 
    Write-Host "ServicePrincipal doesn't exist. Creating Service Principal..." -ForegroundColor Red
    #Create Service Principal 

    # Create the Password Credential Object
    [Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential]`
        $PasswordCredential = @{
        StartDate = Get-Date;
        EndDate   = (Get-Date).AddYears(5);
        Password  = $ADSPPassword
        }

    $ServicePrincipal = New-AzADServicePrincipal -DisplayName $ADServicePrincipal -PasswordCredential $PasswordCredential
}
else { 
    Write-Host "$ADServicePrincipal exist" -ForegroundColor Green
    $ServicePrincipal = Get-AzureADServicePrincipal -Filter "DisplayName eq '$ADServicePrincipal'"
}

#Get Azure AD Directory Role
#$DirectoryRole = Get-AzureADDirectoryRole -Filter "DisplayName eq 'Directory readers'"
$DirectoryRole = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq "Directory readers"} #If the line above doesn't work with the Filter param, then do this.

if ($DirectoryRole -eq $NULL) {
    Write-Output "Directory Reader role not found. This usually occurs when the role has not yet been used in your directory"
    Write-Output "As a workaround, try assigning this role manually to the AzOps App in the Azure portal"
}
else {
    #Add service principal to Directory Role
    Add-AzureADDirectoryRoleMember -ObjectId $DirectoryRole.ObjectId -RefObjectId $ServicePrincipal.ObjectId
}