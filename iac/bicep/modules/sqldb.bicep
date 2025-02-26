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

@description('Database SKU name, e.g P3. For valid values, run this CLI az sql db list-editions -l australiaeast -o table')
param database_sku_name string ='GP_S_Gen5_1'

@description('Time in minutes after which database is automatically paused')
param auto_pause_duration int =60

@description('Flag to indicate whether to enable audit logging of SQL Server')
param enable_audit bool = false

// Variables
var suffix = uniqueString(resourceGroup().id)
var sqlserver_unique_name = '${sqlserver_name}-${suffix}'

// Deploy SQL Server
resource sqlserver 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlserver_unique_name
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  identity: { type: 'SystemAssigned' }
  properties: {
    administrators: {
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
resource allowAzure_Firewall 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlserver
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Deploy database
resource database 'Microsoft.Sql/servers/databases@2021-11-01' = {
  name: database_name
  location: location
  tags: {
    CostCentre: cost_centre_tag
    Owner: owner_tag
    SME: sme_tag
  }
  sku: { name: database_sku_name }
  parent: sqlserver
  properties: {
    autoPauseDelay: auto_pause_duration
  }
}

// Deploy audit diagnostics Azure SQL Server to storage account
resource sqlserver_audit 'Microsoft.Sql/servers/auditingSettings@2023-08-01-preview' = if(enable_audit) {
  name: 'default'
  parent: sqlserver
  properties: {
    auditActionsAndGroups: ['BATCH_COMPLETED_GROUP', 'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP', 'FAILED_DATABASE_AUTHENTICATION_GROUP']
    isAzureMonitorTargetEnabled: true
    isDevopsAuditEnabled: true
    isManagedIdentityInUse: true
    isStorageSecondaryKeyInUse: false
    retentionDays: 90
    state: 'Enabled'
    storageAccountSubscriptionId: subscription().subscriptionId
  }
}

output sqlserver_uniquename string = sqlserver.name
output database_name string = database.name
output sqlserver_resource object = sqlserver
output database_resource object = database
