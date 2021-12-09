#bicep build .\AzureAnalyticsE2E.bicep

az login 

az account set --subscription 96bd7145-ad7f-445a-9763-862e32480bf1

az deployment group create -f .\AzureAnalyticsE2E.bicep -g azvnetdeploy10 --parameters deploymentMode=vNet
