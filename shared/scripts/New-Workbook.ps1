#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Title,
    [Parameter(Mandatory)][string]$Domain
)
$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..' '..'
$dir = Join-Path $root 'workbooks' $Name
New-Item -ItemType Directory -Path $dir -Force | Out-Null

Set-Content (Join-Path $dir 'workbook.json') '{"version":"Notebook/1.0","items":[]}'

$mainBicep = @"
@description('Display name shown in the Azure Monitor Workbooks gallery.')
param displayName string = '$Title'
@description('Scope the workbook queries run against. Defaults to the deployment subscription.')
param sourceId string = subscription().id

module workbook '../../shared/modules/workbook.bicep' = {
  name: 'deploy-$Name'
  params: {
    displayName: displayName
    serializedData: loadTextContent('workbook.json')
    sourceId: sourceId
  }
}
output workbookId string = workbook.outputs.workbookId
"@
Set-Content (Join-Path $dir 'main.bicep') $mainBicep

$meta = [ordered]@{
    id = $Name; title = $Title; domain = $Domain; version = '1.0.0'
    dataSources = @('Azure Resource Graph'); rbac = @('Reader')
    path = "workbooks/$Name"
} | ConvertTo-Json -Depth 5
Set-Content (Join-Path $dir 'metadata.json') $meta

Set-Content (Join-Path $dir 'README.md') "# $Title`n`nDomain: $Domain`n`n<!-- Deploy to Azure button added on publish -->`n"
Write-Host "Scaffolded workbooks/$Name"
