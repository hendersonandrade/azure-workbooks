# Governance & Security Posture

Domain: governance

## Overview

Provides a read-only view of your Azure governance and security posture using 100% Azure Resource Graph queries. Requires the **Reader** role on target subscriptions. Full Defender for Cloud data (secure score and assessments) additionally requires the **Security Reader** role.

## Tiles

|#|Title|What it shows|
|---|---|---|
|1|**Policy compliance by state**|Resource counts grouped by compliance state (`Compliant`, `NonCompliant`, `Exempt`, etc.) across all policy assignments in scope.|
|2|**Non-compliant resources by initiative**|Non-compliant policy states grouped by initiative (policy set) name and individual policy name, ordered by count descending.|
|3|**Defender for Cloud secure score**|Current and maximum secure score for each subscription in scope, with the percentage calculated.|
|4|**Top Defender recommendations**|Unhealthy Defender for Cloud assessments (recommendations) aggregated by display name and severity, ordered by number of affected resources descending.|
|5|**RBAC role assignments overview**|Count of role assignments grouped by principal type (`User`, `Group`, `ServicePrincipal`, etc.).|
|6|**Key Vault secrets/certs nearing expiry (30 days)**|Secrets and certificates from all Key Vaults that have an expiry set and expire within the next 30 days, ordered by expiry date ascending.|

## Requirements

|Requirement|Value|
|---|---|
|Data source|Azure Resource Graph|
|Minimum RBAC|Reader (on target subscription(s))|
|Additional RBAC|**Security Reader** — required for Defender for Cloud secure score (tile 3) and recommendations (tile 4) data|
|Parameter|**Subscriptions** — multi-select subscription picker|

> **Note:** Without the Security Reader role, tiles 3 and 4 (Defender for Cloud secure score and top recommendations) will return no data. The remaining tiles only require Reader.

## Deploy paths

### Option 1 — Deploy-to-Azure button (portal)

> **Note:** Replace `<RAW_BASE_URL>` with the raw content base URL of this repository before publishing (e.g. `https://raw.githubusercontent.com/<org>/<repo>/<ref>`).

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/<RAW_BASE_URL>%2Fworkbooks%2Fgovernance-security%2Fazuredeploy.json)

### Option 2 — Azure CLI

```bash
az deployment group create \
  --resource-group <YOUR-RG> \
  --template-file workbooks/governance-security/azuredeploy.json \
  --parameters workbooks/governance-security/azuredeploy.parameters.json
```

### Option 3 — Deploy-Workbook.ps1

```powershell
pwsh -File shared/scripts/Deploy-Workbook.ps1 `
     -Name governance-security `
     -ResourceGroup <YOUR-RG>
```
