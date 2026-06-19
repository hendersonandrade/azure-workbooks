# Security Policy

## Overview

The Azure Workbooks library follows security best practices to ensure safe deployment and operation in production Azure environments.

## Security Principles

- **Read-Only by Design:** All workbooks run under the viewer's existing Azure RBAC permissions and perform read-only operations on Azure resources
- **No Embedded Secrets:** Workbooks contain no hardcoded credentials, API keys, or sensitive data
- **Query Isolation:** Azure Resource Graph (ARG) queries are scoped to minimize data exposure

## Workbook Execution

Workbooks execute in the context of the authenticated user and respect the user's Azure RBAC role assignments. Data visualization and queries are limited to resources the viewer already has permission to access.

## Reporting Security Issues

If you discover a security vulnerability in this library, please report it directly to the maintainer:

**Email:** hendersonandrade@outlook.com.br

**Please include:**
- A description of the vulnerability
- Steps to reproduce (if applicable)
- Affected workbook(s) or query(ies)
- Suggested remediation (if known)

Reports will be reviewed promptly and addressed with appropriate updates.

## Compliance

Workbooks are designed to:
- Comply with Azure best practices for data governance
- Support compliance and audit requirements via ARG metadata
- Allow deployment in regulated environments with appropriate Azure RBAC policies

## Updates

Security updates will be released as soon as practical and documented in the CHANGELOG.md.
