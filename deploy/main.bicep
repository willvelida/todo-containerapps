@description('The location to deploy our Azure resources to. Default is location of resource group')
param location string = resourceGroup().location

@description('The name of our application')
param applicationName string = 'wvtodo'

@description('Minimum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplicas int = 1

@description('Maximum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplicas int = 3

var logAnalyticsWorkspaceName = 'law${applicationName}'
var logAnalyticsSku = 'PerGB2018'
var containerRegistryName = 'acr${applicationName}'
var containerAppEnvName = 'env${applicationName}'
var todoApiName = '${applicationName}-api'
var apimName = '${applicationName}-apim'
var apimPublisherName = 'Will Velida'
var apimPublisherEmail = 'willvelida@microsoft.com'
var apimSku = 'Developer'
var cpuCore = '0.5'
var memorySize = '1'
var apiName = 'Todo'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: logAnalyticsSku
    }
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  } 
}

resource todoApi 'Microsoft.App/containerApps@2022-03-01' = {
  name: todoApiName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false        
      }
      secrets: [
        {
          name: 'registrypassword'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'registrypassword'
        }
      ]
    }
    template: {
      containers: [
        {
          image: 'acrwvtodo.azurecr.io/todoapi:3edce8e805f91b9fd5e8920799448593f4f5de91'
          name: todoApiName
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: apimName
  location: location
  sku: {
    capacity: 1
    name: apimSku
  }
  properties: {
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: apiName
  parent: apim
  properties: {
    path: 'Todo'
    apiType: 'http'
    displayName: apiName
    format: 'swagger-json'
    type: 'http'
    serviceUrl: 'https://${todoApi.properties.configuration.ingress.fqdn}'
    protocols: [
      'http'
      'https'
    ]
  }
}

resource getTodosOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'getTodos'
  parent: api
  properties: {
    displayName: 'GET Todos'
    urlTemplate: '/Todo'
    method: 'GET'
  }
}
