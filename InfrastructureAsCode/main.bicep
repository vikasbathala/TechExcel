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

// Networking Resources

@description('Name of the virtual network')
var vnetName = '${uniqueString(resourceGroup().id)}-vnet'

@description('Name of the subnet')
var subnetName = 'devsubnet'

@description('Name of the Azure Firewall subnet')
var firewallSubnetName = 'AzureFirewallSubnet'

@description('Name of the NSG')
var nsgName = '${uniqueString(resourceGroup().id)}-nsg'

@description('Name of the firewall')
var firewallName = '${uniqueString(resourceGroup().id)}-firewall'

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
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}


@description('Name of the private endpoint for the storage account')
var privateEndpointName = '${uniqueString(resourceGroup().id)}-storage-pe'

@description('Name of the private DNS zone for the storage account')
var privateDnsZoneName = 'privatelink.blob.core.windows.net'

// Private Endpoint for Storage Account
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-02-01' = {
  name: privateEndpointName
  location: 'East US 2'
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'storageAccountBlobConnection'
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

// Private DNS Zone for Storage Account
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global' // Private DNS zones are always in the 'global' location
  properties: {}
}

// Virtual Network Link for Private DNS Zone
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneName}/${vnetName}-link'
  location: 'East US 2'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
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

@description('Name of the public IP for the Azure Firewall')
var publicIpName = '${uniqueString(resourceGroup().id)}-firewall-pip'

// Public IP Address
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard' // Required for Azure Firewall
  }
  properties: {
    publicIPAllocationMethod: 'Static' // Static IP allocation
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, firewallSubnetName)
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
