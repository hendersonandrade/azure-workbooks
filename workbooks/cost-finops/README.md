# Cost & FinOps

Domain: cost

## Overview

Provides a read-only view of orphaned resources, idle spend, and tagging hygiene across your Azure estate using Azure Resource Graph queries. A direct link to live cost time-series analysis via Azure Cost Management is also included.

## Tiles

|#|Title|What it shows|
|---|---|---|
|1|**Untagged resources by type**|Resource counts grouped by type where the `tags` property is empty or null, ordered by count descending. Identifies tagging gaps that break cost allocation.|
|2|**Orphaned managed disks (unattached)**|Managed disks in the `Unattached` disk state, projected with name, resource group, location, size in GB, and SKU. Ordered by size descending to surface the highest-cost orphans first.|
|3|**Unassociated public IPs (idle spend)**|Public IP addresses with no `ipConfiguration` association, meaning they are reserved but unused and still incur a charge.|
|4|**Empty NICs (not attached to a VM)**|Network interfaces where `properties.virtualMachine` is null, indicating the NIC is no longer attached to any virtual machine.|
|5|**Stopped-but-not-deallocated VMs**|Virtual machines whose power state (from `properties.extended.instanceView.powerState.displayStatus`) is `VM stopped` rather than deallocated. Stopped-but-not-deallocated VMs continue to accrue compute charges.|
|6|**Inventory by CostCenter tag**|Resource counts grouped by the `CostCenter` tag value. Resources missing the tag are grouped as `(untagged)`. Useful for charge-back and show-back reporting.|
|7|**Cost trend (Cost Management link)**|Markdown tile with a direct link to [Cost analysis](https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis) in the Azure portal. Live cost time-series requires the Cost Management Reader role and is accessed through the portal rather than ARG.|

## Requirements

|Requirement|Value|
|---|---|
|Data sources|Azure Resource Graph|
|Minimum RBAC|**Reader** (on target subscription(s))|
|Parameter|**Subscriptions** — multi-select subscription picker|

> **Note:** The workbook itself needs only **Reader** to load and run all its queries. The "Cost trend" tile (tile 7) is a deep link to the Azure portal Cost analysis blade; viewing costs there requires the **Cost Management Reader** role in the portal (not to load this workbook).

## Deploy paths

### Option 1 — Deploy-to-Azure button (portal)

> **Note:** Replace `<RAW_BASE_URL>` with the raw content base URL of this repository before publishing (e.g. `https://raw.githubusercontent.com/<org>/<repo>/<ref>`).

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/<RAW_BASE_URL>%2Fworkbooks%2Fcost-finops%2Fazuredeploy.json)

### Option 2 — Azure CLI

```bash
az deployment group create \
  --resource-group <YOUR-RG> \
  --template-file workbooks/cost-finops/azuredeploy.json \
  --parameters workbooks/cost-finops/azuredeploy.parameters.json
```

### Option 3 — Deploy-Workbook.ps1

```powershell
pwsh -File shared/scripts/Deploy-Workbook.ps1 `
     -Name cost-finops `
     -ResourceGroup <YOUR-RG>
```
