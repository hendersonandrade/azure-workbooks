# Azure Workbooks Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an enterprise-grade, deploy-ready Azure Monitor Workbooks library with four flagship workbooks (Cost/FinOps, Governance/Security, Operations, Networking/Inventory), a shared Bicep deployment module, PowerShell tooling, credential-free CI, and complete documentation.

**Architecture:** Monorepo where each workbook is a self-contained folder (serialized `workbook.json` + `main.bicep` + compiled `azuredeploy.json` + `metadata.json` + README). All workbooks deploy through one shared `shared/modules/workbook.bicep` module that creates the `Microsoft.Insights/workbooks@2023-06-01` resource. Workbooks are ARG-first for zero-setup portability; Log Analytics tiles are optional and gated behind a workspace parameter.

**Tech Stack:** Azure Bicep + compiled ARM JSON, Azure Resource Graph (KQL), PowerShell 7 (Az module), GitHub Actions, Azure Monitor Workbooks JSON schema.

## Global Constraints

- Workbook resource type/API: `Microsoft.Insights/workbooks@2023-06-01`, `kind: 'shared'`.
- `serializedData` is a JSON **string**; load from file with `loadTextContent('workbook.json')`.
- Workbook resource `name` must be a GUID — derive deterministically: `guid(resourceGroup().id, displayName)`.
- ARG-first: every workbook must function with only the **Reader** role unless its `metadata.json` documents otherwise. Log Analytics tiles are optional, gated by a `logAnalyticsWorkspaceId` parameter (empty string = hidden via conditional visibility).
- License: **MIT**. Author: **Henderson Andrade** <hendersonandrade@outlook.com.br>. No third-party/company branding.
- Each `workbook.json` must be valid JSON with top-level keys `version` (`"Notebook/1.0"`) and `items` (array).
- Do not auto-commit beyond the per-task commits in this plan; never add Claude as author/co-author (use the author identity above).
- CI must be credential-free: no `az login`, no live Azure deployment.

---

## File Structure

```
azure-workbooks/
├── README.md  LICENSE  CHANGELOG.md  CONTRIBUTING.md  SECURITY.md  .gitignore
├── catalog.json
├── .github/workflows/validate.yml
├── docs/{getting-started,authoring-guide,deployment}.md  docs/images/
├── shared/modules/workbook.bicep
├── shared/scripts/{Deploy-Workbook.ps1,Build-Arm.ps1,New-Workbook.ps1}
└── workbooks/<domain>/{workbook.json,main.bicep,azuredeploy.json,azuredeploy.parameters.json,metadata.json,README.md}
```

A standard "workbook tile" envelope used by every `workbook.json` (reference shape — Task 2 defines it once, all workbook tasks reuse it):

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "<KQL/ARG QUERY HERE>",
    "size": 0,
    "title": "<TILE TITLE>",
    "queryType": 1,
    "resourceType": "microsoft.resourcegraph/resources",
    "crossComponentResources": ["{Subscriptions}"],
    "visualization": "table"
  }
}
```

- `queryType: 1` + `resourceType: "microsoft.resourcegraph/resources"` = Azure Resource Graph query.
- `crossComponentResources: ["{Subscriptions}"]` binds the query to the subscription picker parameter.
- For Log Analytics tiles: `queryType: 0`, `resourceType: "microsoft.operationalinsights/workspaces"`, and a `conditionalVisibility` block keyed off the workspace parameter.

---

## Task 1: Repository meta scaffolding

**Files:**
- Create: `LICENSE`, `.gitignore`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, `README.md` (skeleton)

**Interfaces:**
- Produces: repo root files referenced by later tasks (README catalog table filled in Task 8).

- [ ] **Step 1: Create `LICENSE`** — MIT license, copyright line: `Copyright (c) 2026 Henderson Andrade`.

- [ ] **Step 2: Create `.gitignore`**

```gitignore
# Bicep / ARM build artifacts that are regenerated
*.bicep.json
# Editor / OS
.vscode/
.DS_Store
Thumbs.db
# PowerShell module cache
*.psd1.bak
```

- [ ] **Step 3: Create `README.md` skeleton** with sections: title `# Azure Workbooks`, one-paragraph description (enterprise, ARG-first, deploy-ready), `## Catalog` (placeholder line `<!-- catalog table generated in Task 8 -->`), `## Quickstart`, `## Repository layout`, `## License (MIT)`, `## Author` (Henderson Andrade).

- [ ] **Step 4: Create `CHANGELOG.md`** following Keep a Changelog format with an `## [Unreleased]` section listing "Initial workbook library scaffolding".

- [ ] **Step 5: Create `CONTRIBUTING.md`** — how to add a workbook via `New-Workbook.ps1`, the folder contract (the 6 files), and that PRs must pass `validate.yml`.

- [ ] **Step 6: Create `SECURITY.md`** — workbooks run read-only under the viewer's RBAC, contain no secrets; report issues to the author email.

- [ ] **Step 7: Verify all files are valid**

Run: `node -e "['LICENSE','.gitignore','CHANGELOG.md','CONTRIBUTING.md','SECURITY.md','README.md'].forEach(f=>require('fs').accessSync(f))" && echo OK`
Expected: `OK`

- [ ] **Step 8: Commit**

```bash
git add LICENSE .gitignore CHANGELOG.md CONTRIBUTING.md SECURITY.md README.md
git commit -m "chore: scaffold repository meta files"
```

---

## Task 2: Shared Bicep workbook module

**Files:**
- Create: `shared/modules/workbook.bicep`
- Create: `shared/modules/workbook.test.bicep` (a thin caller used only to compile-validate the module)

**Interfaces:**
- Produces: module `workbook.bicep` with params `displayName` (string), `serializedData` (string), `sourceId` (string), `category` (string, default `'workbook'`), `location` (string, default `resourceGroup().location`), `tags` (object, default `{}`). Output: `workbookId` (string, the resource id). Every workbook's `main.bicep` consumes this.

- [ ] **Step 1: Write the module**

```bicep
@description('Display name shown in the Azure Monitor Workbooks gallery.')
param displayName string

@description('The serialized workbook JSON content (load with loadTextContent in the caller).')
param serializedData string

@description('Scope the workbook queries against. Use a subscription or resource id; "Azure Monitor" for a generic gallery workbook.')
param sourceId string = 'Azure Monitor'

@description('Workbook gallery category.')
param category string = 'workbook'

@description('Deployment location.')
param location string = resourceGroup().location

@description('Resource tags.')
param tags object = {}

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, displayName)
  location: location
  kind: 'shared'
  tags: tags
  properties: {
    displayName: displayName
    serializedData: serializedData
    category: category
    sourceId: sourceId
    version: 'Notebook/1.0'
  }
}

@description('Resource id of the deployed workbook.')
output workbookId string = workbook.id
```

- [ ] **Step 2: Write the compile-validation caller**

```bicep
// shared/modules/workbook.test.bicep — compile-only smoke test for the module
module wb 'workbook.bicep' = {
  name: 'wbTest'
  params: {
    displayName: 'Test Workbook'
    serializedData: '{"version":"Notebook/1.0","items":[]}'
  }
}
```

- [ ] **Step 3: Verify the module compiles**

Run: `az bicep build --file shared/modules/workbook.test.bicep --stdout > /dev/null && echo OK`
Expected: `OK` (no compile errors). If `az` is unavailable, use `bicep build shared/modules/workbook.test.bicep --stdout`.

- [ ] **Step 4: Commit**

```bash
git add shared/modules/workbook.bicep shared/modules/workbook.test.bicep
git commit -m "feat: add shared Microsoft.Insights/workbooks bicep module"
```

---

## Task 3: PowerShell tooling

**Files:**
- Create: `shared/scripts/Build-Arm.ps1`, `shared/scripts/Deploy-Workbook.ps1`, `shared/scripts/New-Workbook.ps1`

**Interfaces:**
- Consumes: `shared/modules/workbook.bicep` (Task 2).
- Produces: `Build-Arm.ps1` compiles every `workbooks/*/main.bicep` to `azuredeploy.json`; `New-Workbook.ps1 -Name <slug> -Title <title> -Domain <domain>` scaffolds a workbook folder with the 6-file contract; `Deploy-Workbook.ps1 -Path <workbookDir> -ResourceGroup <rg> [-SubscriptionId <id>]` deploys one workbook.

- [ ] **Step 1: Write `Build-Arm.ps1`**

```powershell
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
```

- [ ] **Step 2: Write `New-Workbook.ps1`** that creates `workbooks/<Name>/` with: `workbook.json` (`{"version":"Notebook/1.0","items":[]}`), `main.bicep` (loads workbook.json, calls `../../shared/modules/workbook.bicep`), `metadata.json` (skeleton with id/title/domain/dataSources/rbac), and `README.md` (title + Deploy-to-Azure placeholder).

```powershell
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
param displayName string = '$Title'
param sourceId string = subscription().id
@description('Optional Log Analytics workspace resource id for optional tiles.')
param logAnalyticsWorkspaceId string = ''

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
```

- [ ] **Step 3: Write `Deploy-Workbook.ps1`**

```powershell
#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$ResourceGroup,
    [string]$SubscriptionId
)
$ErrorActionPreference = 'Stop'
if ($SubscriptionId) { az account set --subscription $SubscriptionId }
$template = Join-Path $Path 'azuredeploy.json'
if (-not (Test-Path $template)) { throw "azuredeploy.json not found in $Path. Run Build-Arm.ps1 first." }
az deployment group create --resource-group $ResourceGroup --template-file $template
```

- [ ] **Step 4: Verify scaffolder works end-to-end (and clean up)**

Run:
```bash
pwsh -File shared/scripts/New-Workbook.ps1 -Name _smoke -Title "Smoke Test" -Domain test
node -e "JSON.parse(require('fs').readFileSync('workbooks/_smoke/workbook.json')); JSON.parse(require('fs').readFileSync('workbooks/_smoke/metadata.json')); console.log('OK')"
az bicep build --file workbooks/_smoke/main.bicep --stdout > /dev/null && echo BICEP_OK
rm -rf workbooks/_smoke
```
Expected: `OK` then `BICEP_OK`, and the `_smoke` folder is removed.

- [ ] **Step 5: Commit**

```bash
git add shared/scripts/Build-Arm.ps1 shared/scripts/New-Workbook.ps1 shared/scripts/Deploy-Workbook.ps1
git commit -m "feat: add build, scaffold, and deploy PowerShell tooling"
```

---

## Task 4: Credential-free CI

**Files:**
- Create: `.github/workflows/validate.yml`
- Create: `shared/scripts/Test-Workbooks.ps1` (lint used by CI and locally)

**Interfaces:**
- Consumes: workbook folders and the shared module.
- Produces: `Test-Workbooks.ps1` which fails (non-zero exit) if any `workbook.json` is invalid JSON or missing `version`/`items`, or any `metadata.json` is invalid JSON.

- [ ] **Step 1: Write `Test-Workbooks.ps1`**

```powershell
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
```

- [ ] **Step 2: Write `validate.yml`**

```yaml
name: validate
on:
  pull_request:
  push:
    branches: [main]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Bicep
        run: |
          curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
          chmod +x bicep && sudo mv bicep /usr/local/bin/bicep
          bicep --version
      - name: Lint workbook JSON
        shell: pwsh
        run: ./shared/scripts/Test-Workbooks.ps1
      - name: Bicep build shared module
        run: bicep build shared/modules/workbook.test.bicep --stdout > /dev/null
      - name: Bicep build all workbooks
        run: |
          for d in workbooks/*/; do
            if [ -f "$d/main.bicep" ]; then echo "Building $d"; bicep build "$d/main.bicep" --stdout > /dev/null; fi
          done
```

- [ ] **Step 3: Verify the linter passes on the current (empty workbooks) tree**

Run: `pwsh -File shared/scripts/Test-Workbooks.ps1`
Expected: `All workbooks valid.` and exit 0 (no workbook folders yet = vacuously valid).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/validate.yml shared/scripts/Test-Workbooks.ps1
git commit -m "ci: add credential-free bicep build + workbook json lint"
```

---

## Task 5: Networking & Inventory workbook (pattern-setter, 100% ARG)

> Built first because it is pure ARG and establishes the workbook.json pattern reused by Tasks 6–8.

**Files:**
- Create: `workbooks/networking-inventory/{workbook.json,main.bicep,metadata.json,azuredeploy.json,azuredeploy.parameters.json,README.md}`

**Interfaces:**
- Consumes: `New-Workbook.ps1` (scaffold), `shared/modules/workbook.bicep`, `Build-Arm.ps1`.
- Produces: a complete deploy-ready workbook folder; the `workbook.json` tile pattern reused by later tasks.

- [ ] **Step 1: Scaffold the folder**

Run: `pwsh -File shared/scripts/New-Workbook.ps1 -Name networking-inventory -Title "Networking & Inventory" -Domain networking`
Expected: `Scaffolded workbooks/networking-inventory`.

- [ ] **Step 2: Author `workbook.json`** — replace the empty `items` with: (a) a header text tile, (b) a subscription parameter, (c) four ARG tiles below. The file's `items` array must contain, in order:

Parameters tile (subscription picker):
```json
{
  "type": 9,
  "content": {
    "version": "KqlParameterItem/1.0",
    "parameters": [
      {
        "id": "sub-param",
        "version": "KqlParameterItem/1.0",
        "name": "Subscriptions",
        "type": 6,
        "isRequired": true,
        "multiSelect": true,
        "quote": "'",
        "delimiter": ",",
        "typeSettings": { "additionalResourceOptions": ["value::all"] }
      }
    ]
  }
}
```

Header text tile:
```json
{ "type": 1, "content": { "json": "## Networking & Inventory\nVNet topology, NSG exposure, public-IP surface, and an estate map. Runs on Azure Resource Graph (Reader role)." } }
```

Tile A — Estate map by type (use the envelope from the File Structure section, `visualization: "table"`):
```kusto
resources
| summarize Count = count() by type, location
| order by Count desc
```

Tile B — Public IP surface:
```kusto
resources
| where type == "microsoft.network/publicipaddresses"
| extend ip = tostring(properties.ipAddress), assoc = tostring(properties.ipConfiguration.id)
| project name, resourceGroup, location, ip, associatedTo = iif(isempty(assoc), "UNUSED", assoc)
| order by associatedTo asc
```

Tile C — NSG rules allowing broad inbound from Internet:
```kusto
resources
| where type == "microsoft.network/networksecuritygroups"
| mv-expand rule = properties.securityRules
| extend r = rule.properties
| where tostring(r.direction) == "Inbound" and tostring(r.access) == "Allow"
| where tostring(r.sourceAddressPrefix) in ("*", "Internet", "0.0.0.0/0")
| project nsg = name, resourceGroup, ruleName = tostring(rule.name), port = tostring(r.destinationPortRange), source = tostring(r.sourceAddressPrefix)
```

Tile D — VNet/subnet/peering inventory:
```kusto
resources
| where type == "microsoft.network/virtualnetworks"
| extend addressSpace = tostring(properties.addressSpace.addressPrefixes)
| extend subnetCount = array_length(properties.subnets), peeringCount = array_length(properties.virtualNetworkPeerings)
| project name, resourceGroup, location, addressSpace, subnetCount, peeringCount
```

For tiles B and C set `visualization: "table"`; for tile A optionally `visualization: "table"` (a graph can be added later). Each ARG tile uses `queryType: 1`, `resourceType: "microsoft.resourcegraph/resources"`, `crossComponentResources: ["{Subscriptions}"]`.

- [ ] **Step 3: Fill `metadata.json`** with `dataSources: ["Azure Resource Graph"]`, `rbac: ["Reader"]`, `version: "1.0.0"`, accurate `title`/`domain`/`path`.

- [ ] **Step 4: Validate JSON + lint**

Run: `pwsh -File shared/scripts/Test-Workbooks.ps1`
Expected: `All workbooks valid.`

- [ ] **Step 5: Compile to ARM**

Run: `az bicep build --file workbooks/networking-inventory/main.bicep --outfile workbooks/networking-inventory/azuredeploy.json && echo OK`
Expected: `OK`; `azuredeploy.json` exists.

- [ ] **Step 6: Create `azuredeploy.parameters.json`** with a `displayName` parameter value `"Networking & Inventory"` and an empty `sourceId` override comment (defaults to `subscription().id`).

- [ ] **Step 7: Write the workbook `README.md`** — what each tile shows, required RBAC (Reader), data source (ARG), the three deploy paths, and a "Deploy to Azure" button. Button URL pattern (URL-encode the raw `azuredeploy.json` path):

```markdown
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/<URL-ENCODED-RAW-azuredeploy.json-URL>)
```

- [ ] **Step 8: Commit**

```bash
git add workbooks/networking-inventory
git commit -m "feat: add Networking & Inventory workbook (ARG)"
```

---

## Task 6: Governance & Security Posture workbook (100% ARG)

**Files:**
- Create: `workbooks/governance-security/{workbook.json,main.bicep,metadata.json,azuredeploy.json,azuredeploy.parameters.json,README.md}`

**Interfaces:**
- Consumes: same tooling/module + the tile pattern from Task 5.
- Produces: deploy-ready governance/security workbook.

- [ ] **Step 1: Scaffold**

Run: `pwsh -File shared/scripts/New-Workbook.ps1 -Name governance-security -Title "Governance & Security Posture" -Domain governance`

- [ ] **Step 2: Author `workbook.json`** — subscription parameter (same as Task 5), header tile, then ARG tiles:

Policy compliance by state:
```kusto
policyresources
| where type == "microsoft.policyinsights/policystates"
| summarize Resources = count() by complianceState = tostring(properties.complianceState)
```

Non-compliant resources by initiative:
```kusto
policyresources
| where type == "microsoft.policyinsights/policystates"
| where tostring(properties.complianceState) == "NonCompliant"
| summarize NonCompliant = count() by initiative = tostring(properties.policySetDefinitionName), policy = tostring(properties.policyDefinitionName)
| order by NonCompliant desc
```

Defender for Cloud secure score:
```kusto
securityresources
| where type == "microsoft.security/securescores"
| extend pct = round(100.0 * todouble(properties.score.current) / todouble(properties.score.max), 1)
| project subscriptionId, current = properties.score.current, max = properties.score.max, percent = pct
```

Top Defender recommendations:
```kusto
securityresources
| where type == "microsoft.security/assessments"
| where tostring(properties.status.code) == "Unhealthy"
| summarize Affected = count() by recommendation = tostring(properties.displayName), severity = tostring(properties.metadata.severity)
| order by Affected desc
```

RBAC role assignments overview:
```kusto
authorizationresources
| where type == "microsoft.authorization/roleassignments"
| summarize Assignments = count() by principalType = tostring(properties.principalType)
```

Key Vault secrets/certs nearing expiry (30 days):
```kusto
resources
| where type == "microsoft.keyvault/vaults/secrets" or type == "microsoft.keyvault/vaults/certificates"
| extend exp = todatetime(properties.attributes.exp)
| where isnotempty(exp) and exp < now(30d)
| project name, type, resourceGroup, expiresOn = exp
| order by expiresOn asc
```

All tiles: `queryType: 1`, `resourceType: "microsoft.resourcegraph/resources"`, `crossComponentResources: ["{Subscriptions}"]`.

- [ ] **Step 3: Fill `metadata.json`** — `dataSources: ["Azure Resource Graph"]`, `rbac: ["Reader", "Security Reader"]` (Security Reader noted as needed for full Defender data).

- [ ] **Step 4: Lint** — Run: `pwsh -File shared/scripts/Test-Workbooks.ps1` → `All workbooks valid.`

- [ ] **Step 5: Compile** — Run: `az bicep build --file workbooks/governance-security/main.bicep --outfile workbooks/governance-security/azuredeploy.json && echo OK`

- [ ] **Step 6: Create `azuredeploy.parameters.json`** (displayName `"Governance & Security Posture"`).

- [ ] **Step 7: Write workbook `README.md`** (tiles, RBAC note about Security Reader, ARG data source, deploy paths + button).

- [ ] **Step 8: Commit**

```bash
git add workbooks/governance-security
git commit -m "feat: add Governance & Security Posture workbook (ARG)"
```

---

## Task 7: Cost & FinOps workbook (ARG + Cost Management)

**Files:**
- Create: `workbooks/cost-finops/{workbook.json,main.bicep,metadata.json,azuredeploy.json,azuredeploy.parameters.json,README.md}`

**Interfaces:**
- Consumes: same tooling/module + tile pattern.
- Produces: deploy-ready cost/FinOps workbook.

- [ ] **Step 1: Scaffold**

Run: `pwsh -File shared/scripts/New-Workbook.ps1 -Name cost-finops -Title "Cost & FinOps" -Domain cost`

- [ ] **Step 2: Author `workbook.json`** — subscription parameter, header tile, then ARG tiles:

Untagged resources:
```kusto
resources
| where tags == "" or isnull(tags) or array_length(todynamic(tostring(tags))) == 0
| summarize Untagged = count() by type
| order by Untagged desc
```

Orphaned managed disks (unattached):
```kusto
resources
| where type == "microsoft.compute/disks"
| where tostring(properties.diskState) == "Unattached"
| project name, resourceGroup, location, sizeGb = toint(properties.diskSizeGB), sku = tostring(sku.name)
| order by sizeGb desc
```

Unassociated public IPs (idle spend):
```kusto
resources
| where type == "microsoft.network/publicipaddresses"
| where isnull(properties.ipConfiguration)
| project name, resourceGroup, location, sku = tostring(sku.name)
```

Empty NICs (not attached to a VM):
```kusto
resources
| where type == "microsoft.network/networkinterfaces"
| where isnull(properties.virtualMachine)
| project name, resourceGroup, location
```

Stopped-but-not-deallocated VMs — note in the tile title this requires the power state via `extend` from `properties.extended.instanceView.powerState.displayStatus` (available in ARG for VMs):
```kusto
resources
| where type == "microsoft.compute/virtualmachines"
| extend powerState = tostring(properties.extended.instanceView.powerState.displayStatus)
| where powerState == "VM stopped"
| project name, resourceGroup, location, powerState, size = tostring(properties.hardwareProfile.vmSize)
```

Inventory by tag (e.g. CostCenter):
```kusto
resources
| extend costCenter = tostring(tags["CostCenter"])
| summarize Resources = count() by costCenter = iif(isempty(costCenter), "(untagged)", costCenter)
| order by Resources desc
```

- [ ] **Step 3: Add the Cost Management tile** — a tile that links to Cost analysis (ARM-backed). Add a text tile documenting that live cost time-series uses the Cost Management data source and requires **Cost Management Reader**, plus a link tile:
```json
{ "type": 1, "content": { "json": "### Cost trend\nLive cost time-series is available via Azure Cost Management (requires the Cost Management Reader role). Open [Cost analysis](https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis) for the selected scope." } }
```

- [ ] **Step 4: Fill `metadata.json`** — `dataSources: ["Azure Resource Graph", "Cost Management"]`, `rbac: ["Reader", "Cost Management Reader"]`.

- [ ] **Step 5: Lint** — `pwsh -File shared/scripts/Test-Workbooks.ps1` → `All workbooks valid.`

- [ ] **Step 6: Compile** — `az bicep build --file workbooks/cost-finops/main.bicep --outfile workbooks/cost-finops/azuredeploy.json && echo OK`

- [ ] **Step 7: Create `azuredeploy.parameters.json`** (displayName `"Cost & FinOps"`) and the workbook `README.md` (tiles, RBAC note, deploy paths + button).

- [ ] **Step 8: Commit**

```bash
git add workbooks/cost-finops
git commit -m "feat: add Cost & FinOps workbook (ARG + Cost Management)"
```

---

## Task 8: Operations & Monitoring workbook (ARG + optional Log Analytics)

**Files:**
- Create: `workbooks/operations-monitoring/{workbook.json,main.bicep,metadata.json,azuredeploy.json,azuredeploy.parameters.json,README.md}`

**Interfaces:**
- Consumes: same tooling/module + tile pattern; demonstrates the LA-gated optional tile.
- Produces: deploy-ready operations workbook with a conditionally-visible Log Analytics section.

- [ ] **Step 1: Scaffold**

Run: `pwsh -File shared/scripts/New-Workbook.ps1 -Name operations-monitoring -Title "Operations & Monitoring" -Domain operations`

- [ ] **Step 2: Add a workspace parameter to `workbook.json`** — in the parameters tile, add a second parameter alongside `Subscriptions`:
```json
{
  "id": "ws-param",
  "version": "KqlParameterItem/1.0",
  "name": "LogAnalyticsWorkspace",
  "label": "Log Analytics workspace (optional)",
  "type": 5,
  "isRequired": false,
  "typeSettings": { "additionalResourceOptions": [], "resourceTypeFilter": { "microsoft.operationalinsights/workspaces": true } }
}
```

- [ ] **Step 3: Author the ARG tiles** (default, always visible):

Resource health snapshot:
```kusto
healthresources
| where type == "microsoft.resourcehealth/availabilitystatuses"
| extend status = tostring(properties.availabilityState)
| summarize Resources = count() by status
```

VM inventory & power state:
```kusto
resources
| where type == "microsoft.compute/virtualmachines"
| extend powerState = tostring(properties.extended.instanceView.powerState.displayStatus)
| summarize Count = count() by powerState, size = tostring(properties.hardwareProfile.vmSize)
| order by Count desc
```

AKS cluster inventory:
```kusto
resources
| where type == "microsoft.containerservice/managedclusters"
| project name, resourceGroup, location, k8sVersion = tostring(properties.kubernetesVersion), provisioning = tostring(properties.provisioningState)
```

Azure Advisor recommendations by category:
```kusto
advisorresources
| where type == "microsoft.advisor/recommendations"
| summarize Count = count() by category = tostring(properties.category), impact = tostring(properties.impact)
| order by Count desc
```

- [ ] **Step 4: Add the optional Log Analytics tile** (CPU time-series), gated by `conditionalVisibility` on the workspace parameter. The tile content:
```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "Perf | where ObjectName == 'Processor' and CounterName == '% Processor Time' | summarize avg(CounterValue) by bin(TimeGenerated, 15m), Computer | render timechart",
    "size": 0,
    "title": "Avg CPU % (last 24h) — requires Log Analytics workspace + Monitoring Reader",
    "queryType": 0,
    "resourceType": "microsoft.operationalinsights/workspaces",
    "crossComponentResources": ["{LogAnalyticsWorkspace}"],
    "visualization": "timechart"
  },
  "conditionalVisibility": { "parameterName": "LogAnalyticsWorkspace", "comparison": "isNotEqualTo", "value": "" }
}
```

- [ ] **Step 5: Fill `metadata.json`** — `dataSources: ["Azure Resource Graph", "Log Analytics (optional)"]`, `rbac: ["Reader", "Monitoring Reader (optional, for Log Analytics tiles)"]`.

- [ ] **Step 6: Lint** — `pwsh -File shared/scripts/Test-Workbooks.ps1` → `All workbooks valid.`

- [ ] **Step 7: Compile** — `az bicep build --file workbooks/operations-monitoring/main.bicep --outfile workbooks/operations-monitoring/azuredeploy.json && echo OK`

- [ ] **Step 8: Create `azuredeploy.parameters.json`** (displayName `"Operations & Monitoring"`) and the workbook `README.md` — explicitly document that the CPU tile is hidden until a workspace is selected and needs Monitoring Reader.

- [ ] **Step 9: Commit**

```bash
git add workbooks/operations-monitoring
git commit -m "feat: add Operations & Monitoring workbook (ARG + optional Log Analytics)"
```

---

## Task 9: Catalog, root README, and docs

**Files:**
- Create: `catalog.json`, `docs/getting-started.md`, `docs/authoring-guide.md`, `docs/deployment.md`, `docs/images/.gitkeep`
- Modify: `README.md` (fill the `## Catalog` table), `CHANGELOG.md` (move scaffolding + 4 workbooks under a `## [0.1.0]` release).

**Interfaces:**
- Consumes: every workbook's `metadata.json`.
- Produces: the discoverable index and end-user documentation.

- [ ] **Step 1: Create `catalog.json`** — an array of the 4 workbooks, each `{ id, title, domain, dataSources, rbac, path }`, copied from each `metadata.json`.

- [ ] **Step 2: Fill the `## Catalog` table in `README.md`** — columns: Workbook | Domain | Data sources | Min RBAC | Deploy. One row per workbook with a relative link to its folder README and a Deploy-to-Azure badge.

- [ ] **Step 3: Write `docs/getting-started.md`** — prerequisites (Azure CLI/PowerShell Az, Bicep), and the three deploy paths with copy-paste commands:
```bash
# Portal: click the Deploy to Azure button in any workbook README
# CLI:
az deployment group create -g <rg> --template-file workbooks/<name>/azuredeploy.json
# PowerShell:
pwsh -File shared/scripts/Deploy-Workbook.ps1 -Path workbooks/<name> -ResourceGroup <rg>
```

- [ ] **Step 4: Write `docs/authoring-guide.md`** — the tile envelope, ARG vs Log Analytics (`queryType` 1 vs 0), the subscription parameter pattern, conditional visibility for optional tiles, and how to add a new workbook with `New-Workbook.ps1` then `Build-Arm.ps1`.

- [ ] **Step 5: Write `docs/deployment.md`** — parameters (`displayName`, `sourceId`, `logAnalyticsWorkspaceId`), scope choices (subscription vs management group), and the least-privilege RBAC matrix per workbook.

- [ ] **Step 6: Update `CHANGELOG.md`** — add `## [0.1.0] - 2026-06-18` listing the four workbooks, shared module, tooling, CI, and docs.

- [ ] **Step 7: Validate everything end-to-end**

Run:
```bash
pwsh -File shared/scripts/Test-Workbooks.ps1
node -e "JSON.parse(require('fs').readFileSync('catalog.json')); console.log('catalog OK')"
for d in workbooks/*/; do az bicep build --file "$d/main.bicep" --stdout > /dev/null && echo "$d OK"; done
```
Expected: `All workbooks valid.`, `catalog OK`, and an `OK` line per workbook.

- [ ] **Step 8: Commit**

```bash
git add catalog.json README.md CHANGELOG.md docs
git commit -m "docs: add catalog, getting-started, authoring and deployment guides"
```

---

## Self-Review notes

- **Spec coverage:** repo structure (T1), shared module (T2), tooling incl. scaffold/build/deploy (T3), credential-free CI + lint (T4), the four flagship workbooks with the exact ARG-first/LA-optional split from the spec (T5 networking, T6 governance/security, T7 cost, T8 operations w/ gated LA tile), catalog + 3 docs (T9). Cost Management portability and per-workbook RBAC are captured in T7 and T9.
- **Placeholders:** ARG/KQL queries are written out verbatim; Bicep and PowerShell are complete. The only intentional fill-on-publish item is the URL-encoded Deploy-to-Azure button target, which depends on the final raw repo URL.
- **Type consistency:** module params (`displayName`, `serializedData`, `sourceId`, `category`, `location`, `tags`) and output `workbookId` are consistent across T2, T3 (`New-Workbook.ps1` main.bicep), and every workbook task. Parameter name `Subscriptions` matches `crossComponentResources: ["{Subscriptions}"]`; `LogAnalyticsWorkspace` matches the gated tile in T8.
```
