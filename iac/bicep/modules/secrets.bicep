@description('Name of the Key Vault')
param keyvault_name string

@description('Array of secrets to be created in the Key Vault')
param secrets array

resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyvault_name
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for secret in secrets: {
  name: secret.name
  parent: keyvault
  properties: {
    value: secret.value
  }
}]
