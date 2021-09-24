#!/bin/bash
# This script requires Azure CLI version 2.25.0 or later. Check version with `az --version`.

# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
$env:ACR_NAME="<azure-registry-url>"
$env:SERVICE_PRINCIPAL_NAME="cloudgen-sp"

# Obtain the full registry ID for subsequent command args
$env:ACR_REGISTRY_ID=$(az acr show --name $env:ACR_NAME --query id --output tsv)

# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
$env:SP_PASSWD=$(az ad sp create-for-rbac --name $env:SERVICE_PRINCIPAL_NAME --scopes $env:ACR_REGISTRY_ID --role acrpull --query password --output tsv)
$env:SP_APP_ID=$(az ad sp list --display-name $env:SERVICE_PRINCIPAL_NAME --query [].appId --output tsv)

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
# Write-Output "Service principal ID: $env:SP_APP_ID"
# Write-Output "Service principal password: $env:SP_PASSWD"