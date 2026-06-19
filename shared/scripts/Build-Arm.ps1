#requires -Version 7.0
<#
.SYNOPSIS  Compile every workbook main.bicep to azuredeploy.json.
#>
[CmdletBinding()]
param([string]$Root = (Join-Path $PSScriptRoot '..' '..'))

$ErrorActionPreference = 'Stop'
$workbooks = Get-ChildItem -Path (Join-Path $Root 'workbooks') -Directory -ErrorAction SilentlyContinue
foreach ($wb in $workbooks) {
    $main = Join-Path $wb.FullName 'main.bicep'
    if (-not (Test-Path $main)) { Write-Warning "No main.bicep in $($wb.Name); skipping"; continue }
    $out = Join-Path $wb.FullName 'azuredeploy.json'
    Write-Host "Building $($wb.Name) -> azuredeploy.json"
    az bicep build --file $main --outfile $out
}
Write-Host 'Done.'
