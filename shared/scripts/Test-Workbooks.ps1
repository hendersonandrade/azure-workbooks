#requires -Version 7.0
[CmdletBinding()]
param([string]$Root = (Join-Path $PSScriptRoot '..' '..'))
$ErrorActionPreference = 'Stop'
$fail = $false
Get-ChildItem (Join-Path $Root 'workbooks') -Directory | ForEach-Object {
    $wbFile = Join-Path $_.FullName 'workbook.json'
    $metaFile = Join-Path $_.FullName 'metadata.json'
    foreach ($f in @($wbFile, $metaFile)) {
        if (-not (Test-Path $f)) { Write-Error "Missing $f"; $script:fail = $true; continue }
        try { $null = Get-Content $f -Raw | ConvertFrom-Json } catch { Write-Error "Invalid JSON: $f"; $script:fail = $true }
    }
    if (Test-Path $wbFile) {
        $wb = Get-Content $wbFile -Raw | ConvertFrom-Json
        if (-not $wb.version) { Write-Error "$wbFile missing 'version'"; $script:fail = $true }
        if ($null -eq $wb.items) { Write-Error "$wbFile missing 'items'"; $script:fail = $true }
    }
}
if ($fail) { exit 1 } else { Write-Host 'All workbooks valid.'; exit 0 }
