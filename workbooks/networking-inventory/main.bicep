@description('Display name shown in the Azure Monitor Workbooks gallery.')
param displayName string = 'Networking & Inventory'
@description('Scope the workbook queries run against. Defaults to the deployment subscription.')
param sourceId string = subscription().id

module workbook '../../shared/modules/workbook.bicep' = {
  name: 'deploy-networking-inventory'
  params: {
    displayName: displayName
    serializedData: loadTextContent('workbook.json')
    sourceId: sourceId
  }
}
output workbookId string = workbook.outputs.workbookId
