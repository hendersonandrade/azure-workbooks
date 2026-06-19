# Azure Workbooks

Enterprise-grade Azure Monitor Workbooks library with an Azure Resource Graph (ARG) first approach. All workbooks are deploy-ready with Bicep and compiled ARM templates, designed for immediate integration into monitoring pipelines.

## Catalog

| Workbook | Domain | Data sources | Min RBAC | Deploy |
| -------- | ------ | ------------ | -------- | ------ |
| [Networking & Inventory](workbooks/networking-inventory/README.md) | networking | Azure Resource Graph | Reader | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhendersonandrade%2Fazure-workbooks%2Fmain%2Fworkbooks%2Fnetworking-inventory%2Fazuredeploy.json) |
| [Governance & Security Posture](workbooks/governance-security/README.md) | governance | Azure Resource Graph | Reader, Security Reader | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhendersonandrade%2Fazure-workbooks%2Fmain%2Fworkbooks%2Fgovernance-security%2Fazuredeploy.json) |
| [Cost & FinOps](workbooks/cost-finops/README.md) | cost | Azure Resource Graph, Cost Management | Reader, Cost Management Reader | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhendersonandrade%2Fazure-workbooks%2Fmain%2Fworkbooks%2Fcost-finops%2Fazuredeploy.json) |
| [Operations & Monitoring](workbooks/operations-monitoring/README.md) | operations | Azure Resource Graph, Log Analytics (optional) | Reader, Monitoring Reader (optional) | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhendersonandrade%2Fazure-workbooks%2Fmain%2Fworkbooks%2Foperations-monitoring%2Fazuredeploy.json) |

> **Note:** `<RAW_BASE_URL>` must be replaced with the URL-encoded raw base URL of this repository before the Deploy to Azure buttons work. See [docs/getting-started.md](docs/getting-started.md) for details.

## Quickstart

1. **Prerequisites:** Azure CLI, Bicep CLI, PowerShell 7+
2. **Scaffold a new workbook:** Use `New-Workbook.ps1` to scaffold a new workbook from the template
3. **Deploy an existing workbook:** Use `Deploy-Workbook.ps1 -Name <workbook> -ResourceGroup <rg>` or the Deploy-to-Azure button in the catalog above
4. **Explore examples:** See `/docs` for workbook patterns and ARG queries

## Repository layout

```
.
├── LICENSE                 # MIT license
├── README.md              # This file
├── .gitignore             # Git ignore rules
├── CHANGELOG.md           # Version history
├── CONTRIBUTING.md        # Contribution guidelines
├── SECURITY.md            # Security policy
├── docs/                  # Documentation
├── shared/
│   ├── modules/           # Shared Bicep modules
│   └── scripts/           # Deployment and utility scripts
└── workbooks/             # Workbook implementations
```

## License

MIT. Copyright (c) 2026 Henderson Andrade.

## Author

Henderson Andrade
