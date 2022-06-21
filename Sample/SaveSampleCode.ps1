

function Save-SynapseSampleArtifacts{
    param (
        [string] $SynapseWorkspaceName,
        [string] $SampleArtifactCollectionName
    )
  
    #Install Synapse PowerShell Module
    if (Get-Module -ListAvailable -Name "Az.Synapse") {
        Write-Host "PowerShell Module Az.Synapse already installed."
    } 
    else {
        Install-Module Az.Synapse -Force
        Import-Module Az.Synapse
    }

    #Add System.Web type to encode/decode URL
    Add-Type -AssemblyName System.Web

    #Authenticate for REST API calls
    $token = (Get-AzAccessToken -Resource "https://dev.azuresynapse.net").Token
    $headers = @{ Authorization = "Bearer $token" }
  
    $synapseTokens = @{"`#`#azsynapsewks`#`#" = $SynapseWorkspaceName; }
    $indexFileUrl = "https://raw.githubusercontent.com/Azure/azure-synapse-analytics-end2end/main/Sample/index.json"
    $sampleCodeIndex = Invoke-WebRequest $indexFileUrl | ConvertFrom-Json

    foreach($sampleArtifactCollection in $sampleCodeIndex)
    {
        Write-Host "Loop Collection: $($sampleArtifactCollection.template)"
        if ($sampleArtifactCollection.template -eq $SampleArtifactCollectionName) {
            Write-Host "Deploying Sample Artifact Collection: $($sampleArtifactCollection.template)"
            Write-Host "-----------------------------------------------------------------------"

            #Create SQL Script artifacts.
            Write-Host "Deploying SQL Scripts:"
            Write-Host "-----------------------------------------------------------------------"
            foreach($sqlScript in $sampleArtifactCollection.artifacts.sqlScripts)
            {
                $definitionFilePath = $sqlScript.definitionFilePath
                $fileContent = Invoke-WebRequest $definitionFilePath

                if ($sqlScript.tokens.length -gt 0) {
                    foreach($token in $sqlScript.tokens)
                    {
                        $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
                    }
                }

                if ($sqlScript.interface.ToLower() -eq "powershell") {
                    Write-Host "Creating SQL Script: $($sqlScript.name) via PowerShell"
                    $definitionFilePath = [guid]::NewGuid()
                    Set-Content -Path $definitionFilePath $fileContent
                    Set-AzSynapseSqlScript -WorkspaceName $SynapseWorkspaceName -Name $sqlScript.name -DefinitionFile $definitionFilePath -FolderPath $sqlScript.workspaceFolderPath
                    Remove-Item -Path $definitionFilePath    
                }
                elseif ($sqlScript.interface.ToLower() -eq "rest")
                {
                    Write-Host "Creating SQL Script: $($sqlScript.name) via REST API"
                    $subresource = "sqlScripts"
                    $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/$subresource/$($sqlScript.name)?api-version=2020-02-01"
            
                    #Assign Synapse Workspace Administrator Role to UAMI
                    $body = $fileContent
                    Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body
                }
            }

            #Create Linked Service artifacts.
            Write-Host "Deploying Linked Service:"
            Write-Host "-----------------------------------------------------------------------"
            foreach($linkedService in $sampleArtifactCollection.artifacts.linkedServices)
            {
                $definitionFilePath = $linkedService.definitionFilePath
                $fileContent = Invoke-WebRequest $definitionFilePath

                if ($linkedService.tokens.length -gt 0) {
                    foreach($token in $linkedService.tokens)
                    {
                        $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
                    }
                }

                if ($sqlScript.interface.ToLower() -eq "powershell") {
                    Write-Host "Creating Linked Service: $($linkedService.name) via PowerShell"
                    $definitionFilePath = [guid]::NewGuid()
                    Set-Content -Path $definitionFilePath $fileContent
                    Set-AzSynapseLinkedService -WorkspaceName $SynapseWorkspaceName -Name $linkedService.name -DefinitionFile $definitionFilePath
                    Remove-Item -Path $definitionFilePath    
                }
                elseif ($sqlScript.interface.ToLower() -eq "rest")
                {
                    Write-Host "Creating Linked Service: $($linkedService.name) via REST API"
                    $subresource = "linkedservices"
                    $uri = "https://$SynapseWorkspaceName.dev.azuresynapse.net/$subresource/$($linkedService.name)?api-version=2020-02-01"
            
                    #Assign Synapse Workspace Administrator Role to UAMI
                    $body = $fileContent
                    Invoke-RestMethod -Method Put -ContentType "application/json" -Uri $uri -Headers $headers -Body $body
                }
            }

            #Create Dataset artifacts.
            Write-Host "Deploying Datasets:"
            Write-Host "-----------------------------------------------------------------------"
            foreach($dataset in $sampleArtifactCollection.artifacts.datasets)
            {
                $definitionFilePath = $dataset.definitionFilePath
                $fileContent = Invoke-WebRequest $definitionFilePath

                if ($dataset.tokens.length -gt 0) {
                    foreach($token in $dataset.tokens)
                    {
                        $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
                    }
                }

                $definitionFilePath = [guid]::NewGuid()
                Set-Content -Path $definitionFilePath $fileContent
                Set-AzSynapseDataset -WorkspaceName $SynapseWorkspaceName -Name $dataset.name -DefinitionFile $definitionFilePath
                Remove-Item -Path $definitionFilePath
            }

            #Create Dataflows artifacts.
            Write-Host "Deploying Dataflows:"
            Write-Host "-----------------------------------------------------------------------"
            foreach($dataflow in $sampleArtifactCollection.artifacts.dataflows)
            {
                $definitionFilePath = $dataflow.definitionFilePath
                $fileContent = Invoke-WebRequest $definitionFilePath

                if ($dataflow.tokens.length -gt 0) {
                    foreach($token in $dataflow.tokens)
                    {
                        $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
                    }
                }

                $definitionFilePath = [guid]::NewGuid()
                Set-Content -Path $definitionFilePath $fileContent
                Set-AzSynapseDataFlow -WorkspaceName $SynapseWorkspaceName -Name $dataflow.name -DefinitionFile $definitionFilePath
                Remove-Item -Path $definitionFilePath
            }

            #Create Pipeline artifacts.
            Write-Host "Deploying Pipelines:"
            Write-Host "-----------------------------------------------------------------------"
            foreach($pipeline in $sampleArtifactCollection.artifacts.pipelines)
            {
                $definitionFilePath = $pipeline.definitionFilePath
                $fileContent = Invoke-WebRequest $definitionFilePath

                if ($pipeline.tokens.length -gt 0) {
                    
                    foreach($token in $pipeline.tokens)
                    {
                        $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
                    }
                }

                $definitionFilePath = [guid]::NewGuid()
                Set-Content -Path $definitionFilePath $fileContent
                Set-AzSynapsePipeline -WorkspaceName $SynapseWorkspaceName -Name $pipeline.name -DefinitionFile $definitionFilePath
                Remove-Item -Path $definitionFilePath
            }

            #Create Notebook artifacts.
            Write-Host "Deploying Notebooks:"
            Write-Host "-----------------------------------------------------------------------"
            foreach($notebook in $sampleArtifactCollection.artifacts.notebooks)
            {
                $definitionFilePath = $notebook.definitionFilePath
                $fileContent = Invoke-WebRequest $definitionFilePath

                if ($notebook.tokens.length -gt 0) {
                    
                    foreach($token in $notebook.tokens)
                    {
                        $fileContent = $fileContent -replace $token, $synapseTokens.Get_Item($token)
                    }
                }

                $definitionFilePath = [guid]::NewGuid()
                Set-Content -Path $definitionFilePath $fileContent
                Set-AzSynapseNotebook -WorkspaceName $SynapseWorkspaceName -Name $notebook.name -DefinitionFile $definitionFilePath -FolderPath $notebook.workspaceFolderPath
                Remove-Item -Path $definitionFilePath
            }
        }
    }
}

Save-SynapseSampleArtifacts "azsynapsewksynt6a3" "SynapseRetail"
