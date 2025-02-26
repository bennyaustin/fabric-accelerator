@description('Name of the Key Vault')
param keyvault_name string

@description('Location where resources will be deployed. Defaults to resource group location')
param location string = resourceGroup().location

@description('Array of secrets to be created in the Key Vault')
param secrets array

resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyvault_name
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for secret in secrets: {
  name: '${keyvault.name}/${secret.name}'
  properties: {
    value: secret.value
  }
}]
