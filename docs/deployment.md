# Deployment Guide

This guide covers deployment parameters, scope options, and the least-privilege RBAC assignments required for each workbook.

## ARM template parameters

Every workbook in this library exposes the following top-level parameters in `azuredeploy.json`:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `displayName` | string | workbook title | Human-readable name shown in the Azure Portal workbook gallery |
| `sourceId` | string | `subscription().id` | Scope the workbook queries run against. Defaults to the deployment subscription; supply a subscription or resource ID to change scope. |
| `location` | string | `[resourceGroup().location]` | Azure region where the `microsoft.insights/workbooks` resource is created. Must be a region that supports Azure Monitor Workbooks |
| `tags` | object | `{}` | Resource tags applied to the workbook resource |

The Operations & Monitoring workbook's optional Log Analytics tile selects its workspace at runtime via an in-workbook parameter (not a deployment parameter); it stays hidden until a workspace is chosen and requires Monitoring Reader on that workspace.

## Scope choices

### Resource group scope (recommended)

Deploy the workbook into a dedicated monitoring resource group. This is the standard pattern and the default for all scripts in this library.

```bash
az deployment group create \
  --resource-group rg-monitoring-prod \
  --template-file workbooks/<name>/azuredeploy.json \
  --parameters displayName="<display name>"
```

Workbooks deployed at resource group scope are visible in Azure Monitor > Workbooks for any user with at least `Reader` on the resource group.

### Subscription scope

To share workbooks across multiple teams without pinning to a resource group, deploy to a subscription-level resource group (for example, `rg-shared-workbooks`) that all teams can read.

```bash
az group create --name rg-shared-workbooks --location eastus

az deployment group create \
  --resource-group rg-shared-workbooks \
  --template-file workbooks/<name>/azuredeploy.json \
  --parameters displayName="<display name>"
```

### Management group scope

Azure Monitor Workbooks are `microsoft.insights/workbooks` resources and must be deployed at resource group scope. For management-group-wide visibility, deploy the workbook into a resource group in the management group's root subscription and grant `Reader` to the management group security principal so all child-subscription users can view it.

```bash
# Grant Reader to the management group on the monitoring resource group
az role assignment create \
  --assignee "<management-group-id>" \
  --role "Reader" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/rg-shared-workbooks"
```

## RBAC matrix

Assign the following roles at the **subscription** level (or management group level) so the workbook can query the required data sources.

> **Principle of least privilege:** grant roles only at the scope the user needs to see. Never assign Contributor or Owner for read-only workbook access.

### Networking & Inventory (`workbooks/networking-inventory`)

| Role | Scope | Why required |
|------|-------|-------------|
| `Reader` | Subscription / Management group | Read all resource types via Azure Resource Graph |

Data sources: Azure Resource Graph only.

### Governance & Security Posture (`workbooks/governance-security`)

| Role | Scope | Why required |
|------|-------|-------------|
| `Reader` | Subscription / Management group | Read resource metadata and policy compliance state via ARG |
| `Security Reader` | Subscription / Management group | Read Microsoft Defender for Cloud secure score and recommendation data via `SecurityResources` ARG table |

Data sources: Azure Resource Graph (`SecurityResources` table requires Security Reader).

### Cost & FinOps (`workbooks/cost-finops`)

| Role | Scope | Why required |
|------|-------|-------------|
| `Reader` | Subscription / Management group | Read resource metadata via Azure Resource Graph |
| `Cost Management Reader` | Billing account, enrollment account, or subscription | Query cost and usage data from Cost Management |

Data sources: Azure Resource Graph + Cost Management.

> **Note:** `Cost Management Reader` is a billing-plane role. For EA (Enterprise Agreement) customers assign it at the enrollment account; for MCA customers assign it at the billing profile or invoice section. For pay-as-you-go subscriptions it can be assigned at subscription scope.

### Operations & Monitoring (`workbooks/operations-monitoring`)

| Role | Scope | Why required |
|------|-------|-------------|
| `Reader` | Subscription / Management group | Read resource metadata via Azure Resource Graph |
| `Monitoring Reader` *(optional)* | Log Analytics workspace | Read heartbeat, alert, and performance data from the Log Analytics workspace. Only required when the `LogAnalyticsWorkspace` parameter is supplied |

Data sources: Azure Resource Graph (always) + Log Analytics (optional — only when a workspace is configured).

## CI/CD integration

### GitHub Actions example

```yaml
- name: Deploy workbook
  run: |
    az deployment group create \
      --resource-group ${{ vars.MONITORING_RG }} \
      --template-file workbooks/networking-inventory/azuredeploy.json \
      --parameters displayName="Networking & Inventory"
  env:
    AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

Authenticate the GitHub Actions runner to Azure using a federated credential (OIDC) with the `azure/login` action — do not store subscription secrets as client secrets.

### Azure DevOps example

```yaml
- task: AzureResourceManagerTemplateDeployment@3
  inputs:
    deploymentScope: 'Resource Group'
    azureResourceManagerConnection: '<service-connection-name>'
    subscriptionId: '<subscription-id>'
    action: 'Create Or Update Resource Group'
    resourceGroupName: 'rg-monitoring-prod'
    location: 'East US'
    templateLocation: 'Linked artifact'
    csmFile: 'workbooks/networking-inventory/azuredeploy.json'
    overrideParameters: '-displayName "Networking & Inventory"'
    deploymentMode: 'Incremental'
```

## Idempotency

All ARM deployments use `Incremental` mode. Re-running a deployment with the same parameters updates the workbook in place without affecting other resources in the resource group. The workbook resource ID is stable across updates because the Bicep module generates a deterministic name from the workbook `id` field.
