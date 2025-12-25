targetScope = 'resourceGroup'

@description('Environment of the web app')
param environment string = 'dev'

@description('Location of services')
param location string = resourceGroup().location


var keyvaultName = '${uniqueString(resourceGroup().id)}kv'

// var webAppName = '${uniqueString(resourceGroup().id)}-${environment}'
// var appServicePlanName = '${uniqueString(resourceGroup().id)}-mpnp-asp'
// var logAnalyticsName = '${uniqueString(resourceGroup().id)}-mpnp-la'
// var appInsightsName = '${uniqueString(resourceGroup().id)}-mpnp-ai'
// var sku = 'B1'
// var registryName = '${uniqueString(resourceGroup().id)}mpnpreg'
// var registrySku = 'S1'
// var imageName = 'techboost/dotnetcoreapp'
// var startupCommand = ''

// TODO: complete this script

// /* ---------------------------
//    Azure Container Registry
// ----------------------------*/

// resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
//   name: registryName
//   location: location
//   sku: {
//     name: registrySku
//   }
//   properties: {
//     adminUserEnabled: false
//   }
// }

// /* -------------------------
//    Log Analytics Workspace
// --------------------------*/
// resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
//   name: logAnalyticsName
//   location: location
//   properties: {
//     retentionInDays: 30
//     sku: {
//       name: 'PerGB2018'
//     }
//   }
// }

// /* -------------------------
//    Application Insights
// --------------------------*/
// resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
//   name: appInsightsName
//   location: location
//   kind: 'web'
//   properties: {
//     Application_Type: 'web'
//     WorkspaceResourceId: logAnalytics.id
//   }
// }

// /* -------------------------
//    App Service Plan
// --------------------------*/
// resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
//   name: appServicePlanName
//   location: location
//   sku: {
//     name: sku
//     capacity: 1
//   }
//   properties: {
//     reserved: true   // Required for Linux
//   }
// }

// /* -------------------------
//    Web App
// --------------------------*/
// resource webApp 'Microsoft.Web/sites@2023-01-01' = {
//   name: webAppName
//   location: location
//   properties: {
//     serverFarmId: appServicePlan.id
//     siteConfig: {
//       linuxFxVersion: 'DOCKER|${containerRegistry.name}.azurecr.io/${uniqueString(resourceGroup().id)}/${imageName}'
//       alwaysOn: true
//       appSettings: [
//         {
//           name: 'DOCKETR_REGISTRY_SERVER_URL'
//           value: 'https://${containerRegistry.name}.azurecr.io'
//         }
//         {
//           name: 'DOCKETR_REGISTRY_SERVER_USERNAME'
//           value: containerRegistry.name
//         }
//         {
//           name: 'DOCKETR_REGISTRY_SERVER_PASSWORD'
//           value: containerRegistry.listCredentials().passwords[0].value
//         }
//         {
//           name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
//           value: appInsights.properties.InstrumentationKey
//         }
//         {
//           name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
//           value: appInsights.properties.ConnectionString
//         }
//         {
//           name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
//           value: '~3'
//         }
//       ]
//     }
//     httpsOnly: true
//   }
// }


resource symbolicname 'Microsoft.KeyVault/vaults@2025-05-01' = {
  location: location
  name: keyvaultName
  properties: {
    tenantId: ${AZURE_TENANT_ID}
    sku: {
      family: 'A'
      name: 'standard'
    }

    // RBAC instead of access policies (best practice)
    enableRbacAuthorization: true

    // Security options
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false

    publicNetworkAccess: 'Enabled'
    softDeleteRetentionInDays: 7
    enableSoftDelete: true
    enablePurgeProtection: false
  }
}
}}
