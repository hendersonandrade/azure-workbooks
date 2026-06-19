# Networking & Inventory

Domain: networking

## Overview

Provides a read-only view of your Azure networking estate using 100% Azure Resource Graph queries. Requires only the **Reader** role — no data-plane access needed.

## Tiles

|#|Title|What it shows|
|---|---|---|
|1|**Estate map by type**|Resource count grouped by `type` and `location`, ordered by count descending. Quick overview of what is deployed and where.|
|2|**Public IP surface**|All `microsoft.network/publicipaddresses` resources with their allocated IP and whether they are associated to a resource or **UNUSED**.|
|3|**NSG rules allowing broad inbound from Internet**|Every NSG security rule that is Inbound + Allow and whose source is `*`, `Internet`, or `0.0.0.0/0`. Highlights over-permissive rules.|
|4|**VNet/subnet/peering inventory**|All virtual networks with their address space, subnet count, and peering count.|

## Requirements

|Requirement|Value|
|---|---|
|Data source|Azure Resource Graph|
|Minimum RBAC|Reader (on target subscription(s))|
|Parameter|**Subscriptions** — multi-select subscription picker|

## Deploy paths

### Option 1 — Deploy-to-Azure button (portal)

> **Note:** Replace `<RAW_BASE_URL>` with the raw content base URL of this repository before publishing (e.g. `https://raw.githubusercontent.com/<org>/<repo>/<ref>`).

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/<RAW_BASE_URL>%2Fworkbooks%2Fnetworking-inventory%2Fazuredeploy.json)

### Option 2 — Azure CLI

```bash
az deployment group create \
  --resource-group <YOUR-RG> \
  --template-file workbooks/networking-inventory/azuredeploy.json \
  --parameters workbooks/networking-inventory/azuredeploy.parameters.json
```

### Option 3 — Deploy-Workbook.ps1

```powershell
pwsh -File shared/scripts/Deploy-Workbook.ps1 `
     -Name networking-inventory `
     -ResourceGroup <YOUR-RG>
```
