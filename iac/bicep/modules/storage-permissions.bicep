@description('Resource name storage account to which permissions are to be granted')
param storage_name string

@description('Resource group of storage account')
param storage_rg string

@description('Managed Identity of the resource being granted permissions')
param principalId string

@description('Flag to grant Storage Blob Data Reader role to the storage account')
param grant_reader bool = true

@description('Flag to grant Storage Blob Data Contributor role to the storage account')
param grant_contributor bool = true

//Get Reference to storage account
resource storage_account 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storage_name
  scope: resourceGroup(storage_rg)
}

//In-built role definition for storage account
@description('This is the built-in Storage Blob Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles')
resource sbdcRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

@description('This is the built-in Storage Blob Reader role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource sbdrRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

//Grant Storage Blob Data Contributor role to resource
resource grant_sbdc_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (grant_contributor) {
  name: guid(subscription().subscriptionId, principalId, sbdcRoleDefinition.id)
  scope: storage_account //needs to be uncommented when this is supported
  properties: {
    principalType: 'ServicePrincipal'
    principalId: principalId
    roleDefinitionId: sbdcRoleDefinition.id
  }
}

//Grant Storage Blob Data Reader role to resource
resource grant_sbdr_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (grant_reader) {
  name: guid(subscription().subscriptionId, principalId, sbdrRoleDefinition.id)
  scope: storage_account //needs to be uncommented when this is supported
  properties: {
    principalType: 'ServicePrincipal'
    principalId: principalId
    roleDefinitionId: sbdrRoleDefinition.id
  }
}
