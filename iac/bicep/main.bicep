// Scope
targetScope = 'resourceGroup'

// Parameters
@description('Microsoft Fabric Resource group location')
param rglocation string = 'westeurope'

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string = 'FabricAccelerator'

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string = 'Mark.Beringer@monocle.co.za'

@description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string = 'Anushka.Monema@monocle.co.za'

@description('Timestamp that will be appended to the deployment name')
param deployment_suffix string = utcNow('sast')

// Variables
var fabric_deployment_name = 'fabric_dataplatform_deployment_${deployment_suffix}'
var keyvault_deployment_name = 'keyvault_deployment_${deployment_suffix}'
var controldb_deployment_name = 'controldb_deployment_${deployment_suffix}'
var secrets_deployment_name = 'secrets_deployment_${deployment_suffix}'

// Deploy Key Vault with default access policies using module
module kv './modules/keyvault.bicep' = {
  name: keyvault_deployment_name
  params: {
    location: rglocation
    keyvault_name: 'ba-kv01-${deployment_suffix}'
    cost_centre_tag: cost_centre_tag
    owner_tag: owner_tag
    sme_tag: sme_tag
  }
}

resource kv_ref 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kv.outputs.keyvault_name
}

// Create necessary secrets in the Key Vault
module secrets './modules/secrets.bicep' = {
  name: secrets_deployment_name
  params: {
    keyvault_name: kv.outputs.keyvault_name
    secrets: [
      {
        name: 'fabric-capacity-admin-username'
        value: 'adminUser' // Replace with actual admin user
      }
      {
        name: 'sqlserver-ad-admin-username'
        value: 'sqlAdminUser' // Replace with actual SQL admin user
      }
      {
        name: 'sqlserver-ad-admin-sid'
        value: 'sqlAdminSid' // Replace with actual SQL admin SID
      }
    ]
  }
}

// Deploy Microsoft Fabric Capacity
module fabric_capacity './modules/fabric-capacity.bicep' = {
  name: fabric_deployment_name
  params: {
    fabric_name: 'bafabric01'
    location: rglocation
    cost_centre_tag: cost_centre_tag
    owner_tag: owner_tag
    sme_tag: sme_tag
    adminUsers: kv_ref.getSecret('fabric-capacity-admin-username')
    skuName: 'F4' // Default Fabric Capacity SKU F2
  }
}

// Deploy SQL control DB
module controldb './modules/sqldb.bicep' = {
  name: controldb_deployment_name
  params: {
    sqlserver_name: 'ba-sql01'
    database_name: 'controlDB'
    location: rglocation
    cost_centre_tag: cost_centre_tag
    owner_tag: owner_tag
    sme_tag: sme_tag
    ad_admin_username: kv_ref.getSecret('sqlserver-ad-admin-username')
    ad_admin_sid: kv_ref.getSecret('sqlserver-ad-admin-sid')
    auto_pause_duration: 60
    database_sku_name: 'GP_S_Gen5_1'
  }
}

// Output the Key Vault name
output keyvault_name string = kv.outputs.keyvault_name
