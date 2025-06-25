@description('Name of SQL Server')
param sqlserver_name string

@description('Name of Database')
param database_name string

@description('Azure Location SQL Server')
param location string = resourceGroup().location

@description('Cost Centre tag that will be applied to all resources in this deployment')
param cost_centre_tag string

@description('System Owner tag that will be applied to all resources in this deployment')
param owner_tag string

@description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
param sme_tag string

@description('AD server admin user name')
@secure()
param ad_admin_username string

@description('SID (object ID) of the server administrator')
@secure()
param ad_admin_sid string

@description('Database SKU name, e.g P3. For valid values, run this CLI az sql db list-editions -l westus -o table')
param database_sku_name string ='GP_S_Gen5_1'

@description('Time in minutes after which database is automatically paused')
param auto_pause_duration int =60

@description('Flag to indicate whether to enable integration of data platform resources with either an existing or new Purview resource')
param enable_purview bool

@description('Flag to indicate whether to enable audit logging of SQL Server')
param enable_audit bool = false

@description('Resource Name of new or existing Purview Account. Specify a resource name if create_purview=true or enable_purview=true')
param purview_resource object

@description('Resource name of audit storage account.')
param audit_storage_name string

@description('Resource group of audit storage account is deployed')
param auditrg string

// Variables
var suffix = uniqueString(resourceGroup().id)
var sqlserver_unique_name = '${sqlserver_name}-${suffix}'

// Deploy SQL Server
resource sqlserver 'Microsoft.Sql/servers@2023-08-01-preview' ={
  name: sqlserver_unique_name
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
    }
  identity:{ type: 'SystemAssigned'}
  properties: {
    administrators:{
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: true
      login: ad_admin_username
      sid: ad_admin_sid
      principalType: 'User'
      tenantId: subscription().tenantId
    }
    minimalTlsVersion: '1.2'

  }
}

// Create firewall rule to Allow Azure services and resources to access this SQL Server
resource allowAzure_Firewall 'Microsoft.Sql/servers/firewallRules@2021-11-01' ={
  name: 'AllowAllWindowsAzureIps'
  parent: sqlserver
  properties:{
    startIpAddress:'0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
// Deploy database
resource database 'Microsoft.Sql/servers/databases@2021-11-01' ={
  name: database_name
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
    }
  sku:{name: database_sku_name}
  parent: sqlserver
  properties: {
    autoPauseDelay:auto_pause_duration
  }
}

//Get Reference to audit storage account
resource audit_storage_account 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if(enable_audit) {
  name: audit_storage_name
  scope: resourceGroup(auditrg)
}

module storage_permissions 'storage-permissions.bicep' = if(enable_audit)  {
  name: 'storage_permissions'
  scope: resourceGroup(auditrg)
  params:{
    storage_name: audit_storage_name
    storage_rg: auditrg
    principalId: sqlserver.identity.principalId
    grant_reader: false
    grant_contributor: true
  }
}

// Deploy audit diagnostics Azure SQL Server to storage account
resource sqlserver_audit 'Microsoft.Sql/servers/auditingSettings@2023-08-01-preview' = if(enable_audit)  {
  name: 'default'
  parent: sqlserver
  properties: {
    auditActionsAndGroups: ['BATCH_COMPLETED_GROUP','SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP','FAILED_DATABASE_AUTHENTICATION_GROUP']
    isAzureMonitorTargetEnabled: true
    isDevopsAuditEnabled: true
    isManagedIdentityInUse: true
    isStorageSecondaryKeyInUse: false
    retentionDays: 90
    state: 'Enabled'
    storageAccountSubscriptionId: subscription().subscriptionId
    storageEndpoint: audit_storage_account.properties.primaryEndpoints.blob
 }
}
//Role Assignment
@description('This is the built-in Storage Blob Reader role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

resource grant_purview_reader_role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (enable_purview){
  name: guid(subscription().subscriptionId, sqlserver.name, readerRoleDefinition.id)
  scope: sqlserver
  properties: {
    principalType: 'ServicePrincipal'
    principalId: purview_resource.identity.principalId
    roleDefinitionId: readerRoleDefinition.id
  }
}
output sqlserver_uniquename string = sqlserver.name
output database_name string = database.name
output sqlserver_resource object = sqlserver
output database_resource object = database
