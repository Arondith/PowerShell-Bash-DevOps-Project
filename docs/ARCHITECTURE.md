# OpsPilot Architecture

OpsPilot implements the same operational workflows in PowerShell and Bash so the repository demonstrates how automation patterns translate across Windows and Linux.

## Components

- PowerShell module: reusable advanced functions in powershell/OpsPilot.psm1
- PowerShell CLI: powershell/opspilot.ps1
- Bash CLI: bash/opspilot.sh
- Automated tests: Pester for PowerShell and an executable Bash test harness
- CI: Bash on Ubuntu plus PowerShell on both Ubuntu and Windows

## Shared workflows

| Command | Purpose | PowerShell | Bash |
| --- | --- | --- | --- |
| system-report | Host/runtime inventory | JSON | JSON |
| health | HTTP availability and latency | JSON | JSON |
| log-scan | Error/warning triage | CSV + summary | CSV + count |
| checksum | SHA256 file-integrity manifest | text | text |
| backup | Timestamped archive | ZIP | tar.gz |

## PowerShell design

The PowerShell side is packaged as a module instead of a single script. Exported functions:

- Get-OpsSystemReport
- Test-OpsEndpoint
- Find-OpsLogIssues
- New-OpsChecksumManifest
- New-OpsBackup

This demonstrates module metadata, parameter validation, structured objects, JSON/CSV output, .NET interoperability, and cross-platform PowerShell.

## Bash design

The Bash implementation uses standard Unix tooling where possible:

- curl for endpoint checks
- awk for log classification
- sha256sum or shasum for integrity manifests
- tar for compressed backups

The CLI uses strict mode, explicit dependency checks, argument validation, and non-zero exit codes on failures.

## Quality strategy

GitHub Actions runs three independent jobs:

1. Bash on Ubuntu: bash -n, ShellCheck, integration tests
2. PowerShell on Ubuntu: PSScriptAnalyzer, manifest validation, Pester
3. PowerShell on Windows: PSScriptAnalyzer, manifest validation, Pester

## Design principles

- fail fast with clear errors
- prefer machine-readable output
- avoid destructive automation
- keep secrets out of source control
- make scripts testable and repeatable
- use platform-native conventions where sensible

## Future improvements

Potential extensions include scheduled health reports, backup retention policies, webhook notifications, JSON log ingestion, remote-host inventory, signed checksum verification, and publishing the PowerShell module to the PowerShell Gallery.