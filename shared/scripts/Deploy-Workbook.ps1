#requires -Version 7.0
[CmdletBinding(DefaultParameterSetName = 'ByName')]
param(
    [Parameter(Mandatory, ParameterSetName = 'ByName')][string]$Name,
    [Parameter(Mandatory, ParameterSetName = 'ByPath')][string]$Path,
    [Parameter(Mandatory)][string]$ResourceGroup,
    [string]$SubscriptionId
)
$ErrorActionPreference = 'Stop'
if ($PSCmdlet.ParameterSetName -eq 'ByName') {
    $Path = Join-Path $PSScriptRoot '..' '..' 'workbooks' $Name
}
if ($SubscriptionId) { az account set --subscription $SubscriptionId }
$template = Join-Path $Path 'azuredeploy.json'
if (-not (Test-Path $template)) { throw "azuredeploy.json not found in $Path. Run Build-Arm.ps1 first." }
az deployment group create --resource-group $ResourceGroup --template-file $template
