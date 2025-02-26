// // Parameters
// @description('Flag to indicate whether to create a new Purview resource with this data platform deployment')
// param create_purview bool=false

// @description('Flag to indicate whether to enable integration of data platform resources with either an existing or new Purview resource')
// param enable_purview bool=true

// @description('Resource Name of new or existing Purview Account. Specify a resource name if create_purview=true or enable_purview=true')
// param purview_name string

// @description('Resource group where Purview will be deployed. Resource group will be created if it doesnt exist')
// param purviewrg string

// @description('Location where resources will be deployed. Defaults to resource group location')
// param location string = resourceGroup().location

// @description('Cost Centre tag that will be applied to all resources in this deployment')
// param cost_centre_tag string

// @description('System Owner tag that will be applied to all resources in this deployment')
// param owner_tag string

// @description('Subject Matter Expert (SME) tag that will be applied to all resources in this deployment')
// param sme_tag string

// // Variables
// // var suffix = uniqueString(resourceGroup().id)
// var purview_uniquename =  purview_name
// var managed_synapse_rg_name = 'mrg_${purview_uniquename}'


// // Create Purview resource
// resource purview_account 'Microsoft.Purview/accounts@2024-04-01-preview'= if (create_purview) {
//   name: purview_uniquename
//   location: location
//   tags: {
//           CostCentre: cost_centre_tag
//           Owner: owner_tag
//           SME: sme_tag
//         }  
//   identity:{
//     type: 'SystemAssigned'
//   }
//   properties:{
//     managedResourceGroupName: managed_synapse_rg_name
//     publicNetworkAccess: 'Enabled'
//   }
//   }
  
//   resource existing_purview_account 'Microsoft.Purview/accounts@2024-04-01-preview' existing = if (!create_purview && enable_purview) {
//     name: purview_uniquename
//     scope: resourceGroup(purviewrg)
//   }

//   output purview_account_name string = create_purview ? purview_account.name: existing_purview_account.name
//   output purview_resourceid string = create_purview ? purview_account.id: existing_purview_account.id
//   output purview_resource object = create_purview ? purview_account: existing_purview_account
 