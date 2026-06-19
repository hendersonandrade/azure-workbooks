# Azure Workbooks Library — Design

**Date:** 2026-06-18
**Author:** Henderson Andrade
**Repo:** `azure-workbooks`
**Status:** Approved (design phase)

## Goal

Build a professional, enterprise-grade library of Azure Monitor Workbooks that are
ready to deploy into any user's Azure environment, with complete documentation. The
library covers four domains and ships with four flagship workbooks in the first pass.

## Principles

- **ARG-first.** Prioritize Azure Resource Graph queries so workbooks run in *any*
  tenant with zero setup and no extra cost. Use Log Analytics / KQL only where it
  genuinely earns its place (time-series performance), and gate those tiles behind an
  optional workspace parameter with clear flagging.
- **Self-contained workbooks.** Each workbook lives in its own folder and is
  independently deployable, reviewable, and documented.
- **DRY deployment.** The `Microsoft.Insights/workbooks` resource is authored once in
  a shared Bicep module; each workbook only supplies its serialized content.
- **Bicep + compiled ARM.** Author in Bicep, emit `azuredeploy.json` so portal users
  get a "Deploy to Azure" button and CLI/PowerShell users get clean IaC.
- **No branding.** Sole author Henderson Andrade; neutral, clean header tiles. MIT license.
- **Quality over quantity.** Workbook JSON is hand-authored with genuinely working ARG
  queries — no stub/placeholder content.

## Approach

Monorepo workbook library with a shared Bicep module. Chosen over a flat JSON dump (no
IaC/parameterization/docs) and a Terraform-driven layout (user selected Bicep+ARM; Bicep
gives a cleaner portal "Deploy to Azure" experience).

## Repository structure

```
azure-workbooks/
├── README.md                 # overview + catalog table + quickstart + badges
├── LICENSE (MIT)  CHANGELOG.md  CONTRIBUTING.md  SECURITY.md  .gitignore
├── catalog.json              # machine-readable index of all workbooks
├── .github/workflows/
│   └── validate.yml          # bicep build + JSON/schema lint on PR (no creds needed)
├── docs/
│   ├── getting-started.md    # 3 deploy paths: portal button, az CLI, PowerShell
│   ├── authoring-guide.md    # how to build/edit; ARG vs Log Analytics; conventions
│   ├── deployment.md         # parameters, scopes, least-privilege RBAC per workbook
│   └── images/               # screenshots referenced by READMEs
├── shared/
│   ├── modules/workbook.bicep        # the one reusable Microsoft.Insights/workbooks module
│   └── scripts/
│       ├── Deploy-Workbook.ps1       # deploy helper
│       ├── Build-Arm.ps1             # bicep build all → azuredeploy.json
│       └── New-Workbook.ps1          # scaffold a new workbook folder
└── workbooks/
    ├── cost-finops/
    ├── governance-security/
    ├── operations-monitoring/
    └── networking-inventory/
         ├── workbook.json                 # serialized workbook definition (the real content)
         ├── main.bicep                     # wraps workbook.json via shared module
         ├── azuredeploy.json               # compiled ARM
         ├── azuredeploy.parameters.json
         ├── metadata.json                  # name, version, category, dataSources, RBAC
         └── README.md                      # what it shows, requirements, deploy button, screenshots
```

## Deployment model

- `shared/modules/workbook.bicep` creates the `Microsoft.Insights/workbooks` resource.
  Inputs: `displayName`, `serializedData` (the workbook JSON content), `sourceId`
  (scope), `category` (default `workbook`), `location`, optional `tags`. The workbook
  `name` (GUID) is derived deterministically with `guid()` from the resource group id
  and display name so redeploys are idempotent.
- Each workbook's `main.bicep` loads `workbook.json` via `loadTextContent()` and passes
  it to the shared module.
- Three documented deploy paths:
  1. **Portal** — "Deploy to Azure" button using `azuredeploy.json`.
  2. **Azure CLI** — `az deployment group create`.
  3. **PowerShell** — `Deploy-Workbook.ps1`.
- **Scope parameter** (subscription or management group resource id) drives the `sourceId`
  so users aim each workbook at their estate.
- **RBAC** documented per workbook in `metadata.json` and the workbook README. Baseline:
  **Reader**. **Monitoring Reader** only for the optional Log Analytics tiles.

## The four flagship workbooks

1. **Cost & FinOps** (`cost-finops`)
   - Untagged resources; orphaned/idle resources (unattached managed disks, unassociated
     public IPs, empty NICs, stopped-not-deallocated VMs).
   - Inventory and count by tag, resource type, location, resource group.
   - Cost Management tiles (ARM data source — portable, no LA workspace required).
   - Data sources: ARG + Cost Management (ARM). RBAC: Reader + Cost Management Reader.

2. **Governance & Security Posture** (`governance-security`) — 100% ARG, zero setup
   - Azure Policy compliance state (compliant/non-compliant by initiative & resource).
   - Defender for Cloud secure score and top recommendations (`securityresources`).
   - RBAC role assignments overview (`authorizationresources`).
   - Key Vault secrets/certificates nearing expiry.
   - Public-exposure findings (resources with public endpoints).
   - Data sources: ARG only. RBAC: Reader (+ Security Reader for full Defender data).

3. **Operations & Monitoring** (`operations-monitoring`)
   - Resource health snapshot (`healthresources`).
   - VM inventory and power state; AKS cluster inventory.
   - Azure Advisor recommendations by category.
   - **Optional** performance time-series tiles (CPU/memory) gated behind a Log Analytics
     workspace parameter using conditional visibility, clearly flagged as requiring a
     workspace + Monitoring Reader.
   - Data sources: ARG (default) + Log Analytics (optional). RBAC: Reader (+ Monitoring
     Reader for the optional tiles).

4. **Networking & Inventory** (`networking-inventory`) — 100% ARG
   - VNet / subnet / peering topology.
   - NSG rule exposure (rules allowing broad inbound from Internet).
   - Public-IP surface (all public IPs and what they front).
   - Resource estate map by type, location, and resource group.
   - Data sources: ARG only. RBAC: Reader.

## Cross-cutting design

- **Data flow:** workbooks run ARG/ARM/LA queries client-side under the viewer's RBAC.
  No backend, no stored data, no secrets.
- **Portability & error handling:** subscription/management-group picker parameters;
  conditional visibility for LA-dependent tiles; graceful empty/"no data" states.
- **Validation / testing (credential-free CI):**
  - `bicep build` on the shared module and every workbook `main.bicep`.
  - JSON validity + minimal schema lint on each `workbook.json` (required keys: `version`,
    `items`) and `metadata.json`.
  - `New-Workbook.ps1` scaffolds new workbook folders from a template for consistency.
  - Manual: screenshots in `docs/images/` demonstrate rendering.
- **Catalog:** `catalog.json` indexes every workbook (id, title, domain, data sources,
  RBAC, path) and the README catalog table is generated to match it.

## Out of scope (first pass)

- More than the four flagship workbooks (added in later passes via `New-Workbook.ps1`).
- Automated Azure deployment in CI (requires credentials; kept credential-free).
- Terraform packaging.

## Components and responsibilities

| Unit | Purpose | Depends on |
|------|---------|------------|
| `shared/modules/workbook.bicep` | Create the workbooks resource (write once) | Azure `Microsoft.Insights/workbooks` |
| `workbooks/<name>/workbook.json` | The serialized workbook definition (content) | ARG / ARM / LA schemas |
| `workbooks/<name>/main.bicep` | Bind one workbook to the shared module | shared module, `workbook.json` |
| `workbooks/<name>/azuredeploy.json` | Portal-deployable compiled ARM | `main.bicep` |
| `shared/scripts/*.ps1` | Deploy, build-arm, scaffold | Az PowerShell / Bicep CLI |
| `catalog.json` + root `README.md` | Discoverable index of the library | per-workbook `metadata.json` |
