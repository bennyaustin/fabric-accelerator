// Parameters
@description('Location where resources will be deployed. Defaults to resource group location')
param location string = resourceGroup().location

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string

@description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string

@description('Key Vault name')
param keyvault_name string

// Variables
var suffix = uniqueString(resourceGroup().id)
var keyvault_uniquename = take('${keyvault_name}${suffix}', 24)

// Create Key Vault
resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyvault_uniquename
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    // Default Access Policies. Replace the ObjectID's with your user/group id
    accessPolicies: [
      { tenantId: subscription().tenantId
        objectId: '30f93c8e-0d25-484d-92cb-532d0828186a' // Mark ObjectID
        permissions: { secrets: ['list', 'get', 'set', 'delete', 'recover'] }
      }
      { tenantId: subscription().tenantId
        objectId: 'a90a3e69-5914-4fa3-b7a4-1180fef0aa41' // Anushka ObjectID
        permissions: { secrets: ['list', 'get', 'set', 'delete', 'recover'] }
      }
      { tenantId: subscription().tenantId
        objectId: '868c7499-b54c-48b3-9030-55f0b79d81b2' // Service principal ID
        permissions: { secrets: ['list', 'get', 'set', 'delete', 'recover'] }
      }
    ]
  }
}

output keyvault_name string = keyvault.name
