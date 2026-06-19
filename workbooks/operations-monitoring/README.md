# Operations & Monitoring

Domain: operations

## Overview

Provides a read-only view of resource health, VM and AKS inventory, Azure Advisor recommendations, and an optional Log Analytics CPU time-series tile across your Azure estate. Always-visible tiles use Azure Resource Graph (Reader role). The CPU tile is hidden until a Log Analytics workspace is selected and requires the Monitoring Reader role.

## Tiles

|#|Title|What it shows|
|---|---|---|
|1|**Resource health snapshot**|Counts of resources grouped by their `availabilityState` from Azure Resource Health (Available, Unavailable, Degraded, Unknown).|
|2|**VM inventory & power state**|Virtual machines grouped by power state and VM size, ordered by count descending. Surfaces running vs. stopped/deallocated distribution.|
|3|**AKS cluster inventory**|Managed Kubernetes clusters projected with name, resource group, location, Kubernetes version, and provisioning state.|
|4|**Azure Advisor recommendations by category**|Advisor recommendations summarised by category (Cost, Security, Reliability, Performance, OperationalExcellence) and impact level, ordered by count descending.|
|5|**Avg CPU % (last 24h)** *(conditional)*|Log Analytics Perf table time-series of average CPU % sampled in 15-minute bins, rendered as a timechart. **This tile is hidden until a Log Analytics workspace is selected in the workspace picker.** It requires the **Monitoring Reader** role on the selected workspace. Once a workspace is chosen the tile becomes visible automatically via `conditionalVisibility`.|

## Requirements

|Requirement|Value|
|---|---|
|Data sources|Azure Resource Graph, Log Analytics (optional)|
|Minimum RBAC|Reader (on target subscription(s))|
|Additional RBAC|**Monitoring Reader** — required to query the Log Analytics workspace for CPU data (tile 5)|
|Parameters|**Subscriptions** — multi-select subscription picker; **Log Analytics workspace (optional)** — single workspace picker|

> **Note:** The CPU tile (tile 5) uses `conditionalVisibility` and is invisible until the `LogAnalyticsWorkspace` parameter is set to a non-empty value. Without the Monitoring Reader role on the workspace, the query will return an access error. Tiles 1-4 only require the Reader role and are always visible.

## Deploy paths

### Option 1 — Deploy-to-Azure button (portal)

> **Note:** Replace `<RAW_BASE_URL>` with the raw content base URL of this repository before publishing (e.g. `https://raw.githubusercontent.com/<org>/<repo>/<ref>`).

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/<RAW_BASE_URL>%2Fworkbooks%2Foperations-monitoring%2Fazuredeploy.json)

### Option 2 — Azure CLI

```bash
az deployment group create \
  --resource-group <YOUR-RG> \
  --template-file workbooks/operations-monitoring/azuredeploy.json \
  --parameters workbooks/operations-monitoring/azuredeploy.parameters.json
```

### Option 3 — Deploy-Workbook.ps1

```powershell
pwsh -File shared/scripts/Deploy-Workbook.ps1 `
     -Name operations-monitoring `
     -ResourceGroup <YOUR-RG>
```
