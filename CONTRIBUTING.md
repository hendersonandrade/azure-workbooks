# Contributing

Thank you for your interest in contributing to the Azure Workbooks library. This document outlines the process for adding new workbooks and maintaining code quality.

## Adding a Workbook

Use the `New-Workbook.ps1` script to scaffold a new workbook:

```powershell
./scripts/New-Workbook.ps1 -Name "MyWorkbookName"
```

This creates a new workbook folder with the required folder contract.

## Workbook Folder Contract

Each workbook must follow this folder structure:

```
workbooks/{workbook-name}/
├── workbook.bicep          # Bicep template for the workbook resource
├── workbook.json           # Compiled ARM template (generated)
├── parameters.json         # Default parameter values
├── README.md               # Workbook documentation
├── queries/                # ARG queries used by the workbook
│   └── *.kql              # Kusto Query Language files
└── examples/               # Example deployments or screenshots
```

## Code Review and Validation

All pull requests must pass the automated validation pipeline:

- **`validate.yml`:** Runs syntax checks, template validation, and integration tests
- Ensure all Bicep files compile without errors
- Ensure all ARG queries are valid Kusto syntax
- Include documentation for new queries or significant logic changes

## Commit Guidelines

- Use descriptive commit messages
- Reference the workbook name in the commit when relevant
- Example: `feat(workbooks/resource-insights): add ARG-based cost analysis`

## Questions?

If you have questions or need clarification, please open an issue or reach out to the maintainer.
