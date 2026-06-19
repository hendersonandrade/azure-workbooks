# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-06-18

### Added

- **Networking & Inventory workbook** (`workbooks/networking-inventory`) — ARG-based inventory of virtual networks, subnets, NSGs, public IPs, and peerings across subscriptions.
- **Governance & Security Posture workbook** (`workbooks/governance-security`) — ARG-based policy compliance, Defender for Cloud secure score, and resource tagging coverage via the `SecurityResources` table.
- **Cost & FinOps workbook** (`workbooks/cost-finops`) — ARG resource inventory combined with Cost Management spend data; supports EA, MCA, and pay-as-you-go billing scopes.
- **Operations & Monitoring workbook** (`workbooks/operations-monitoring`) — ARG-based VM and resource health tiles with optional Log Analytics heartbeat and alert tiles gated behind conditional visibility.
- **Shared Bicep module** (`shared/modules/workbook.bicep`) — reusable `microsoft.insights/workbooks` module consumed by all four workbooks; exposes `displayName`, `serializedData`, `sourceId`, `category`, `location`, and `tags` parameters.
- **PowerShell tooling** (`shared/scripts/`) — `New-Workbook.ps1` (scaffold), `Build-Arm.ps1` (Bicep-to-ARM compile), `Deploy-Workbook.ps1` (deploy), and `Test-Workbooks.ps1` (validation).
- **CI pipeline** — credential-free GitHub Actions workflow with Bicep lint, ARM template validation, and workbook JSON schema checks on every pull request.
- **Documentation** — `docs/getting-started.md`, `docs/authoring-guide.md`, `docs/deployment.md`, and root `catalog.json` discoverable index.
