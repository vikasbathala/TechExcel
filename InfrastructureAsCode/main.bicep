targetScope = 'resourceGroup'

@description('Environment of the web app')
param environment string = 'dev'

@description('Location of services')
param location string = resourceGroup().location


var keyvaultName = '${uniqueString(resourceGroup().id)}kv${environment}'

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


resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  location: location
  name: keyvaultName
  properties: {
    tenantId: '00b64bf0-90ae-4837-9d26-71d72801b61a'
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
    enablePurgeProtection: true
  }
}

@description('Name of the storage account')
var storageAccountName = '${uniqueString(resourceGroup().id)}st${environment}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS' // Local-redundant storage
  }
  kind: 'StorageV2' // General-purpose v2 storage account
  properties: {
    accessTier: 'Hot' // Hot or Cool access tier
    allowBlobPublicAccess: false // Disable public access for security
    minimumTlsVersion: 'TLS1_2' // Enforce minimum TLS version
    supportsHttpsTrafficOnly: true // Enforce HTTPS traffic only
  }
}

// Networking Resources

@description('Name of the virtual network')
var vnetName = '${uniqueString(resourceGroup().id)}-vnet'

@description('Name of the subnet')
var subnetName = 'devsubnet'

@description('Name of the NSG')
var nsgName = '${uniqueString(resourceGroup().id)}-nsg'

@description('Name of the firewall')
var firewallName = '${uniqueString(resourceGroup().id)}-firewall'

@description('Name of the private endpoint')
var privateEndpointName = '${uniqueString(resourceGroup().id)}-private-endpoint'

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-02-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
  }
}

// Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-02-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'storageConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}
