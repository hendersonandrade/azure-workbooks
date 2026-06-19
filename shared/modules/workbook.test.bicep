// shared/modules/workbook.test.bicep — compile-only smoke test for the module
module wb 'workbook.bicep' = {
  name: 'wbTest'
  params: {
    displayName: 'Test Workbook'
    serializedData: '{"version":"Notebook/1.0","items":[]}'
  }
}
