# Getting Started

This guide covers the prerequisites and the three supported deployment paths for workbooks in this library.

## Prerequisites

| Tool | Minimum version | Purpose |
|------|----------------|---------|
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | 2.50.0 | Deploying ARM templates and Bicep files via `az deployment group create` |
| [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) | 0.22.0 | Building Bicep source to ARM JSON (`az bicep install`) |
| [PowerShell](https://github.com/PowerShell/PowerShell/releases) | 7.2 (LTS) | Running the helper scripts in `shared/scripts/` |
| [Az PowerShell module](https://learn.microsoft.com/en-us/powershell/azure/install-az-ps) | 11.0 | Used by `Deploy-Workbook.ps1` for ARM deployments |

Install the Bicep CLI extension for Azure CLI if not already present:

```bash
az bicep install
az bicep version   # confirm
```

Install the Az PowerShell module:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

## Authentication

All deployment paths require an authenticated session with permission to create resources in the target resource group.

```bash
# Azure CLI
az login
az account set --subscription "<subscription-id>"
```

```powershell
# PowerShell
Connect-AzAccount
Set-AzContext -SubscriptionId "<subscription-id>"
```

## Deploy Path 1 — Azure Portal button

Each workbook README contains a **Deploy to Azure** button. Clicking it opens the Azure Portal custom deployment blade pre-populated with the ARM template from that workbook folder.

> **Note:** The Deploy to Azure button links to a raw GitHub URL. The placeholder `<RAW_BASE_URL>` in the workbook READMEs must be replaced with the actual raw base URL of the published repository before the button works. Example pattern:
> `https://portal.azure.com/#create/Microsoft.Template/uri/<URL-encoded raw URL to azuredeploy.json>`

## Deploy Path 2 — Azure CLI

Use this path for scripted or CI/CD deployments.

```bash
# Replace <name> with the workbook folder name and <rg> with your resource group
az deployment group create \
  --resource-group <rg> \
  --template-file workbooks/<name>/azuredeploy.json \
  --parameters displayName="My Workbook"
```

Available workbook names: `cost-finops`, `governance-security`, `networking-inventory`, `operations-monitoring`.

Full example for the Networking & Inventory workbook:

```bash
az deployment group create \
  --resource-group rg-monitoring-prod \
  --template-file workbooks/networking-inventory/azuredeploy.json \
  --parameters displayName="Networking & Inventory"
```

### Optional parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `displayName` | workbook title | Display name shown in the Azure Portal |
| `sourceId` | `"azure monitor"` | Source workbook gallery identifier |
| `location` | resource group location | Azure region for the workbook resource |

## Deploy Path 3 — PowerShell helper script

The `Deploy-Workbook.ps1` script wraps the ARM deployment and surfaces progress output.

```powershell
pwsh -File shared/scripts/Deploy-Workbook.ps1 -Path workbooks/<name> -ResourceGroup <rg>
```

Full example:

```powershell
pwsh -File shared/scripts/Deploy-Workbook.ps1 `
  -Path workbooks/cost-finops `
  -ResourceGroup rg-monitoring-prod
```

Additional parameters accepted by the script:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-Path` | Yes | Relative or absolute path to the workbook folder |
| `-ResourceGroup` | Yes | Target resource group name |
| `-DisplayName` | No | Override the workbook display name |
| `-Location` | No | Azure region (defaults to resource group location) |

## Rebuilding ARM templates from Bicep source

If you modify a workbook's `main.bicep` or the shared module, rebuild the compiled ARM template before deploying:

```powershell
pwsh -File shared/scripts/Build-Arm.ps1 -Path workbooks/<name>
```

Or build all workbooks at once:

```powershell
Get-ChildItem workbooks -Directory | ForEach-Object {
    pwsh -File shared/scripts/Build-Arm.ps1 -Path $_.FullName
}
```

## Validating the library

Run the test suite to confirm all workbook JSON files and metadata are well-formed:

```powershell
pwsh -File shared/scripts/Test-Workbooks.ps1
```

Expected output: `All workbooks valid.`
