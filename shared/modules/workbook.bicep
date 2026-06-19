@description('Display name shown in the Azure Monitor Workbooks gallery.')
param displayName string

@description('The serialized workbook JSON content (load with loadTextContent in the caller).')
param serializedData string

@description('Scope the workbook queries against. Use a subscription or resource id; "Azure Monitor" for a generic gallery workbook.')
param sourceId string = 'Azure Monitor'

@description('Workbook gallery category.')
param category string = 'workbook'

@description('Deployment location.')
param location string = resourceGroup().location

@description('Resource tags.')
param tags object = {}

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, displayName)
  location: location
  kind: 'shared'
  tags: tags
  properties: {
    displayName: displayName
    serializedData: serializedData
    category: category
    sourceId: sourceId
    version: 'Notebook/1.0'
  }
}

@description('Resource id of the deployed workbook.')
output workbookId string = workbook.id
