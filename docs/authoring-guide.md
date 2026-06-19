# Authoring Guide

This guide explains the workbook JSON structure used in this library, query patterns, parameter conventions, and how to scaffold and publish a new workbook.

## Workbook JSON structure

Each workbook is defined in `workbook.json` inside its folder. At the top level the file is a standard Azure Monitor serialized workbook object. The library wraps it in a Bicep module (`shared/modules/workbook.bicep`) that injects the `serializedData` string into an ARM `microsoft.insights/workbooks` resource.

### Tile envelope

Every query tile in `workbook.json` follows this envelope:

```json
{
  "type": 3,
  "content": {
    "version": "KqlItem/1.0",
    "query": "<KQL or ARG query string>",
    "size": 0,
    "queryType": 1,
    "resourceType": "microsoft.resourcegraph/resources",
    "crossComponentResources": ["{Subscriptions}"],
    "visualization": "table",
    "gridSettings": { ... }
  },
  "name": "tile-name"
}
```

Key fields:

| Field | Value | Meaning |
|-------|-------|---------|
| `type` | `3` | Query tile |
| `queryType` | `1` | Azure Resource Graph (ARG) |
| `queryType` | `0` | Log Analytics workspace |
| `resourceType` | `"microsoft.resourcegraph/resources"` | Required when `queryType` is `1` |
| `crossComponentResources` | `["{Subscriptions}"]` | Resolved at runtime from the Subscriptions parameter |

Text tiles use `"type": 1` and `"content": { "json": "..." }`. Group tiles use `"type": 12`.

## ARG vs Log Analytics queries

### Azure Resource Graph (`queryType: 1`)

Use ARG for inventory, compliance, and configuration queries. ARG does not require a Log Analytics workspace and works across all subscriptions in scope.

```json
{
  "query": "Resources | where type =~ 'microsoft.network/virtualnetworks' | project name, location, resourceGroup, subscriptionId | order by name asc",
  "queryType": 1,
  "resourceType": "microsoft.resourcegraph/resources",
  "crossComponentResources": ["{Subscriptions}"]
}
```

ARG queries use [Kusto Query Language (KQL)](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/) against the `Resources`, `ResourceContainers`, `PolicyResources`, `SecurityResources`, and related ARG tables.

### Log Analytics (`queryType: 0`)

Use Log Analytics for operational telemetry — metrics, alerts, diagnostic logs, and performance data.

```json
{
  "query": "Heartbeat | summarize LastHeartbeat = max(TimeGenerated) by Computer | extend Status = iff(LastHeartbeat > ago(5m), 'Online', 'Offline')",
  "queryType": 0,
  "crossComponentResources": ["{LogAnalyticsWorkspace}"]
}
```

The `crossComponentResources` array references the `LogAnalyticsWorkspace` parameter (see below). Unlike ARG tiles, Log Analytics tiles require a workspace to be selected; wrap them in a conditional visibility block if the workspace is optional.

## Parameter patterns

### Subscriptions parameter

All workbooks declare a multi-subscription parameter so the user can scope the workbook at runtime. The standard pattern used in this library:

```json
{
  "id": "subscription-param",
  "version": "KqlParameterItem/1.0",
  "name": "Subscriptions",
  "type": 6,
  "isRequired": true,
  "multiSelect": true,
  "quote": "'",
  "delimiter": ",",
  "value": [],
  "typeSettings": {
    "additionalResourceOptions": ["value::all"],
    "includeAll": true
  },
  "label": "Subscriptions"
}
```

`type: 6` is the built-in Azure subscription picker. Setting `value: []` with `"value::all"` causes all subscriptions to be selected by default.

### LogAnalyticsWorkspace parameter

Used by workbooks that have optional Log Analytics tiles (for example, `operations-monitoring`):

```json
{
  "id": "law-param",
  "version": "KqlParameterItem/1.0",
  "name": "LogAnalyticsWorkspace",
  "type": 5,
  "isRequired": false,
  "value": "",
  "typeSettings": {
    "resourceTypeFilter": {
      "microsoft.operationalinsights/workspaces": true
    },
    "additionalResourceOptions": []
  },
  "label": "Log Analytics Workspace (optional)"
}
```

`type: 5` is the resource picker. Setting `isRequired: false` and `value: ""` leaves the parameter empty by default so the workbook renders without a workspace configured.

## Conditional visibility for optional tiles

When a tile depends on an optional parameter, wrap it in a group with a conditional visibility expression. The `operations-monitoring` workbook uses this pattern for its Log Analytics tile:

```json
{
  "type": 12,
  "content": {
    "version": "NotebookGroup/1.0",
    "groupType": "editable",
    "items": [
      {
        "type": 3,
        "content": {
          "query": "Heartbeat | ...",
          "queryType": 0,
          "crossComponentResources": ["{LogAnalyticsWorkspace}"]
        },
        "name": "la-heartbeat"
      }
    ]
  },
  "conditionalVisibility": {
    "parameterName": "LogAnalyticsWorkspace",
    "comparison": "isNotEqualTo",
    "value": ""
  },
  "name": "la-group"
}
```

The `conditionalVisibility` block on the group hides all child tiles when `LogAnalyticsWorkspace` is empty. This keeps the workbook fully functional for users who only have ARG access, while enabling richer telemetry for those who supply a workspace.

## Adding a new workbook

### Step 1 — Scaffold

Run `New-Workbook.ps1` to generate the folder structure, `main.bicep`, `workbook.json` stub, `metadata.json`, `azuredeploy.json` placeholder, and `README.md`:

```powershell
pwsh -File shared/scripts/New-Workbook.ps1 -Id "my-new-workbook" -Title "My New Workbook" -Domain "operations"
```

This creates `workbooks/my-new-workbook/` with all required files.

### Step 2 — Author workbook.json

Edit `workbooks/my-new-workbook/workbook.json` to define your tiles, parameters, and layout. Follow the tile envelope and parameter patterns documented above.

Guidelines:
- Use ARG (`queryType: 1`) as the primary data source wherever possible — ARG queries work without additional resource access beyond `Reader`.
- Add Log Analytics tiles only as optional overlays behind a `conditionalVisibility` block.
- Keep the `Subscriptions` parameter as the first parameter so users can immediately scope the workbook.
- Name every tile with a unique, kebab-cased `name` field to aid debugging and link navigation.

### Step 3 — Update metadata.json

Edit `workbooks/my-new-workbook/metadata.json` to reflect the correct `dataSources` and minimum `rbac` roles. This file is the source of truth for `catalog.json`.

### Step 4 — Build ARM template

Compile the Bicep source to an ARM JSON template:

```powershell
pwsh -File shared/scripts/Build-Arm.ps1 -Path workbooks/my-new-workbook
```

This writes `workbooks/my-new-workbook/azuredeploy.json`.

### Step 5 — Validate

```powershell
pwsh -File shared/scripts/Test-Workbooks.ps1
```

Expected: `All workbooks valid.`

### Step 6 — Update catalog.json

Add an entry to the root `catalog.json` array copied from the new `metadata.json` (omit the `version` field — catalog entries carry only `id`, `title`, `domain`, `dataSources`, `rbac`, `path`).

### Step 7 — Add a row to the README catalog table

Add a row to the `## Catalog` table in `README.md` following the existing format.

## Shared Bicep module reference

The shared module at `shared/modules/workbook.bicep` accepts these parameters:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `displayName` | string | Yes | Display name shown in the Azure Portal workbook gallery |
| `serializedData` | string | Yes | The full contents of `workbook.json` as a serialized string |
| `sourceId` | string | No | Gallery source id (default: `"azure monitor"`) |
| `category` | string | No | Gallery category (default: `"workbook"`) |
| `location` | string | No | Azure region (default: resource group location) |
| `tags` | object | No | Azure resource tags |

Output: `workbookId` (string) — the resource ID of the deployed workbook.
